import test from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import 'dotenv/config';

import { app, connectDb } from '../src/app.js';
import mongoose from 'mongoose';

// A real, minimal 1x1 PNG (used so the mock ML service can "read" a file).
const TINY_PNG = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  'base64',
);

// ── In-process mock FastAPI ────────────────────────────────────────────────
function startMockML() {
  return new Promise((resolve) => {
    const server = http.createServer((req, res) => {
      const chunks = [];
      req.on('data', (c) => chunks.push(c));
      req.on('end', () => {
        if (req.url.startsWith('/predict/image')) {
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(
            JSON.stringify({
              success: true,
              message: 'Detection completed.',
              data: {
                verdict: 'AI',
                confidence: 87.4,
                label: 'AI Generated',
                modelName: 'mock-inference',
                processingMs: 12,
              },
            }),
          );
        } else if (req.url.startsWith('/predict/video')) {
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(
            JSON.stringify({
              success: true,
              message: 'Detection completed.',
              data: {
                verdict: 'Real',
                confidence: 92.0,
                label: 'Real / Human-made',
                modelName: 'mock-inference',
                processingMs: 22,
                framesAnalyzed: 10,
              },
            }),
          );
        } else if (req.url.startsWith('/health')) {
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ status: 'ok' }));
        } else {
          res.writeHead(404, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ success: false }));
        }
      });
    });
    server.listen(0, '127.0.0.1', () => resolve(server));
  });
}

function startApp() {
  return new Promise((resolve) => {
    const server = app.listen(0, '127.0.0.1', () =>
      resolve({ server, port: server.address().port }),
    );
  });
}

async function jsonRequest(base, method, path, { token, body, multipart } = {}) {
  const headers = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  let payload = null;
  if (multipart) {
    const boundary = `----test${Date.now()}`;
    const fileName = multipart.fileName;
    const fileType = multipart.fileType || 'image/png';
    headers['Content-Type'] = `multipart/form-data; boundary=${boundary}`;
    payload = Buffer.concat([
      Buffer.from(
        `--${boundary}\r\nContent-Disposition: form-data; name="modelId"\r\n\r\n${multipart.modelId}\r\n`,
      ),
      Buffer.from(
        `--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="${fileName}"\r\nContent-Type: ${fileType}\r\n\r\n`,
      ),
      multipart.bytes,
      Buffer.from(`\r\n--${boundary}--\r\n`),
    ]);
  } else if (body) {
    headers['Content-Type'] = 'application/json';
    payload = Buffer.from(JSON.stringify(body));
  }
  const res = await fetch(`http://127.0.0.1:${base}${path}`, {
    method,
    headers,
    body: payload,
  });
  const text = await res.text();
  return { status: res.status, body: text ? JSON.parse(text) : {} };
}

let mLServer;
let api;

test.before(async () => {
  if (!process.env.MONGODB_URI) {
    throw new Error('MONGODB_URI is required to run integration tests');
  }
  mLServer = await startMockML();
  process.env.FASTAPI_URL = `http://127.0.0.1:${mLServer.address().port}`;
  await connectDb();
  api = await startApp();
});

test.after(async () => {
  mLServer?.close();
  api?.server?.close();
  await mongoose.connection.close();
});

test('full pipeline: auth -> upload -> ML -> MongoDB -> history', async () => {
  const email = `itest_${process.pid}_${Date.now()}@example.com`;

  // 1. Signup
  let r = await jsonRequest(api.port, 'POST', '/api/auth/register', {
    body: { name: 'Integ Test', email, password: 'secret123' },
  });
  assert.equal(r.status, 201);
  assert.equal(r.body.success, true);
  assert.ok(r.body.token, 'register returns a JWT');
  const token = r.body.token;

  // 2. Login with the same credentials
  r = await jsonRequest(api.port, 'POST', '/api/auth/login', {
    body: { email, password: 'secret123' },
  });
  assert.equal(r.status, 200);
  assert.equal(r.body.user.email, email);

  // 3. Invalid login is rejected
  r = await jsonRequest(api.port, 'POST', '/api/auth/login', {
    body: { email, password: 'wrong-password' },
  });
  assert.equal(r.status, 401);
  assert.equal(r.body.success, false);
  assert.equal(r.body.error.code, 'UNAUTHORIZED');

  // 4. Unauthorized request without a token
  r = await jsonRequest(api.port, 'GET', '/api/detections');
  assert.equal(r.status, 401);

  // 5. Expired/invalid JWT is rejected
  r = await jsonRequest(api.port, 'GET', '/api/detections', {
    token: 'not-a-real-jwt',
  });
  assert.equal(r.status, 401);

  // 6. Upload + analyze an image through the ML service
  r = await jsonRequest(api.port, 'POST', '/api/detections/analyze', {
    token,
    multipart: {
      modelId: '01',
      fileName: 'sample.png',
      fileType: 'image/png',
      bytes: TINY_PNG,
    },
  });
  assert.equal(r.status, 201, JSON.stringify(r.body));
  assert.equal(r.body.prediction.verdict, 'AI');
  assert.ok(r.body.detection._id);

  // 7. The detection is persisted and returned in history
  r = await jsonRequest(api.port, 'GET', '/api/detections', { token });
  assert.equal(r.status, 200);
  const saved = r.body.detections.find((d) => d.fileName === 'sample.png');
  assert.ok(saved, 'detection saved to MongoDB and returned in history');
  assert.equal(saved.verdict, 'AI');

  // 8. User stats reflect the scan
  r = await jsonRequest(api.port, 'GET', '/api/user/stats', { token });
  assert.equal(r.status, 200);
  assert.ok(r.body.stats.totalScans >= 1);

  // 9. Non-admin cannot call admin APIs
  r = await jsonRequest(api.port, 'GET', '/api/admin/stats/overview', { token });
  assert.equal(r.status, 403);
  assert.equal(r.body.error.code, 'FORBIDDEN');

  // 10. Invalid file type is rejected before reaching the ML service
  r = await jsonRequest(api.port, 'POST', '/api/detections/analyze', {
    token,
    multipart: {
      modelId: '01',
      fileName: 'evil.exe',
      fileType: 'application/x-msdownload',
      bytes: Buffer.from('not an image'),
    },
  });
  assert.equal(r.status, 400);
  assert.equal(r.body.error.code, 'INVALID_FILE_TYPE');

  // 11. Oversized file rejected (limit mocked low)
  const oldLimit = process.env.MAX_IMAGE_SIZE_MB;
  process.env.MAX_IMAGE_SIZE_MB = '0.000001';
  r = await jsonRequest(api.port, 'POST', '/api/detections/analyze', {
    token,
    multipart: { modelId: '01', fileName: 'big.png', bytes: TINY_PNG },
  });
  process.env.MAX_IMAGE_SIZE_MB = oldLimit;
  assert.equal(r.status, 413);
  assert.equal(r.body.error.code, 'FILE_TOO_LARGE');

  // 12. Admin can list overview after being promoted
  const adminUser = await mongoose.models.User.findOne({ email }).select('+password');
  adminUser.isAdmin = true;
  await adminUser.save();
  try {
    r = await jsonRequest(api.port, 'GET', '/api/admin/stats/overview', { token });
    assert.equal(r.status, 200);
    assert.ok(r.body.stats.totalUsers >= 1);
  } finally {
    // Cleanup test user and its detections.
    await mongoose.models.Detection.deleteMany({ userId: adminUser._id });
    await adminUser.deleteOne();
  }
});