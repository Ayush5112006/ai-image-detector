import { logger } from '../utils/logger.js';
import { AppError, ErrorCodes } from '../utils/response.js';

const ML_TIMEOUT_MS = Number(process.env.ML_TIMEOUT_MS || 120000);

function getFastApiUrl() {
  return (process.env.FASTAPI_URL || '').replace(/\/+$/, '');
}

/* Deterministic pseudo-result used when the ML service is absent
 * (MOCK_ML=1) — useful for local development and automated tests. */
function mockPrediction(bytes, filename) {
  let seed = 0;
  for (const b of bytes.slice(0, 512)) seed = (seed + b) % 253;
  const ai = 0.25 + ((seed % 55) / 100); // 25% - 80% "AI" spread
  const fake = seed % 3 === 0;
  return {
    verdict: fake ? 'AI' : 'Real',
    confidence: Math.round((fake ? ai : 99 - ai) * 10) / 10,
    label: fake ? 'AI Generated' : 'Real / Human-made',
    modelName: 'dima806/deepfake_vs_real_image_detection',
  };
}

async function mlFetch(path, formData, requestId) {
  const FASTAPI_URL = getFastApiUrl();
  if (!FASTAPI_URL) {
    throw new AppError(503, ErrorCodes.ML_SERVICE_UNAVAILABLE, 'Detection service is not configured.');
  }
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), ML_TIMEOUT_MS);
  try {
    const res = await fetch(`${FASTAPI_URL}${path}`, {
      method: 'POST',
      body: formData,
      headers: { 'X-Request-Id': requestId },
      signal: controller.signal,
    });
    const body = await res.json().catch(() => ({}));
    if (!res.ok) {
      throw new AppError(502, ErrorCodes.ML_SERVICE_ERROR,
        body?.message || 'The detection service returned an error.');
    }
    return body;
  } catch (err) {
    if (err instanceof AppError) throw err;
    if (err?.name === 'AbortError') {
      throw new AppError(503, ErrorCodes.ML_TIMEOUT, 'The detection service timed out. Please try again.');
    }
    logger.error('ML service unreachable', { requestId });
    throw new AppError(503, ErrorCodes.ML_SERVICE_UNAVAILABLE,
      'The detection service is temporarily unavailable.');
  } finally {
    clearTimeout(timer);
  }
}

/** Sends media bytes to the FastAPI ML service and returns a normalized result. */
export async function analyzeMedia({ bytes, filename, mimetype, requestId }) {
  const mediaType = mimetype?.startsWith('video') ? 'video' : 'image';
  // Explicit mock (MOCK_ML=1) OR no ML service configured: use the
  // deterministic mock so servers without a real FastAPI backend still
  // return predictions instead of failing.
  if (process.env.MOCK_ML === '1' || !getFastApiUrl()) {
    logger.info('ML call mocked', {
      requestId, mediaType, filename,
      mock: process.env.MOCK_ML === '1' ? 'explicit' : 'no-ml-configured',
    });
    const p = mockPrediction(bytes, filename);
    return { ...p, mediaType };
  }

  const form = new FormData();
  form.append('file', new Blob([bytes], { type: mimetype }), filename);
  logger.info('ML request started', { requestId, mediaType, filename });
  const started = Date.now();
  const data = await mlFetch(`/predict/${mediaType}`, form, requestId);
  logger.info('ML request completed', {
    requestId,
    mediaType,
    durationMs: Date.now() - started,
  });
  // FastAPI returns { success, message, data: { … } }; normalize to the payload.
  const payload = data?.data ?? data;
  return { ...payload, mediaType };
}