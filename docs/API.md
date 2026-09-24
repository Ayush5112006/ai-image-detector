# ChitraVision AI — API Documentation

This document describes the **ChitraVision AI** REST APIs:

1. [Conventions](#conventions)
2. [Node.js Backend API](#nodejs-backend-api) (`:4000` — production: Render)
3. [FastAPI ML Service](#fastapi-ml-service) (`:8000` — production: Render)
4. [OpenAPI / Swagger](#openapi--swagger)

> **Security note:** no secrets, JWT secrets, MongoDB credentials or private
> configuration values appear in this document or in any example.

---

## Conventions

### Standard response envelope (Node.js backend)

| Kind | Shape |
| --- | --- |
| Success | `{ "success": true, "message": "<text>", "data": { ... } }` |
| Error   | `{ "success": false, "message": "<text>", "error": { "code": "CODE" } }` |

On success the payload (`token`, `user`, `detections`, …) is nested under a
**`data`** key. Error payloads are never wrapped in `data`. (A previous version
spread payload fields at the top level; this was changed to a stable envelope.)

### HTTP status codes

| Status | Meaning |
| --- | --- |
| 200 | Success |
| 201 | Created |
| 400 | Bad request / invalid parameters |
| 401 | Unauthorized (missing, invalid or expired JWT) |
| 403 | Forbidden (authenticated but not allowed) |
| 404 | Not found |
| 409 | Conflict (e.g. email already registered) |
| 413 | File too large |
| 422 | Validation error |
| 502 | Upstream ML service returned an error |
| 503 | ML service unavailable or timed out |
| 500 | Unexpected server error |

### Error codes (Node.js backend)

| Code | Meaning |
| --- | --- |
| `VALIDATION_ERROR` | Missing/invalid parameters |
| `UNAUTHORIZED` | Missing/invalid/expired token |
| `FORBIDDEN` | Not an admin |
| `NOT_FOUND` | Resource does not exist |
| `CONFLICT` | Duplicate unique value |
| `FILE_TOO_LARGE` | Upload exceeded limit |
| `INVALID_FILE_TYPE` | Unsupported file format |
| `ML_SERVICE_UNAVAILABLE` | ML service not reachable/not configured |
| `ML_TIMEOUT` | ML inference timed out |
| `ML_SERVICE_ERROR` | ML service returned an error |
| `EMAIL_ERROR` | Failed to send email |
| `INTERNAL_ERROR` | Unexpected server error |

### Authentication

All endpoints under `/api/detections`, `/api/user` and `/api/admin` require a
Bearer JWT:

```
Authorization: Bearer <token>
```

The JWT is issued on `register` / `login` and is valid for **30 days**.

---

## Node.js Backend API

Base URL: `http://localhost:4000` (dev) / your deployed backend.

### 1. Authentication

#### `POST /api/auth/register` — Create an account

Registration requires a one-time code that the **server** generated and emailed
(see [`POST /api/auth/send-otp`](#post-apiauthsend-otp--send-a-registration-verification-code)).
The code is single-use, scoped to the email, and expires after 5 minutes.

- **Auth:** none
- **Headers:** `Content-Type: application/json`
- **Body:**
  ```json
  { "name": "Ayush", "email": "ayush@example.com", "password": "secret123", "otp": "123456" }
  ```
- **Success 201:**
  ```json
  {
    "success": true,
    "message": "Account created successfully.",
    "data": {
      "token": "eyJhbGciOi...",
      "user": {
        "_id": "667f...", "name": "Ayush", "email": "ayush@example.com",
        "xp": 0, "premium": { "active": false, "expiresAt": null },
        "createdAt": "2026-09-21T08:00:00.000Z", "updatedAt": "2026-09-21T08:00:00.000Z"
      }
    }
  }
  ```
- **Errors:** `400 VALIDATION_ERROR` missing fields / short password / invalid or expired OTP · `409 CONFLICT` email exists

#### `POST /api/auth/login` — Sign in

- **Auth:** none
- **Body:** `{ "email": "...", "password": "..." }`
- **Success 200:** same shape as `register`
- **Errors:** `400 VALIDATION_ERROR` · `401 UNAUTHORIZED` incorrect credentials

#### `GET /api/auth/me` — Current profile

- **Auth:** `Bearer <token>`
- **Success 200:** `{ "success": true, "message": "Profile loaded.", "data": { "user": {...} } }`
- **Error:** `401 UNAUTHORIZED`

#### `PATCH /api/auth/me` — Update profile

- **Auth:** `Bearer <token>`
- **Body:** any of `{ "name", "phone", "location", "bio" }`
- **Success 200:** `{ "data": { "user": {...} } }`
- **Errors:** `400 VALIDATION_ERROR` nothing to update · `401 UNAUTHORIZED`

#### `POST /api/auth/send-otp` — Send a registration verification code

- **Auth:** none
- **Body:** `{ "email": "..." }` (the server generates a 6-digit code, stores a
  bcrypt hash, and emails it)
- **Success 200:** `{ "success": true, "message": "OTP sent" }`
- **Errors:** `400 VALIDATION_ERROR` · `502 EMAIL_ERROR` mail server failure

#### `POST /api/auth/change-password` — Change password while signed in

- **Auth:** `Bearer <token>`
- **Body:** `{ "currentPassword": "...", "newPassword": "newpass123" }`
- **Success 200:** `{ "success": true, "message": "Password changed successfully." }`
- **Errors:** `400 VALIDATION_ERROR` short password · `401 UNAUTHORIZED` wrong current password

#### `POST /api/auth/forgot-password` — Request a password reset code

- **Auth:** none
- **Body:** `{ "email": "..." }`
- **Success 200 (always generic — prevents account enumeration):**
  ```json
  { "success": true, "message": "If an account exists for that email, a reset code has been sent." }
  ```
- **Errors:** `400 VALIDATION_ERROR` missing email · `502 EMAIL_ERROR`

#### `POST /api/auth/reset-password` — Set a new password with the code

- **Auth:** none
- **Body:** `{ "email": "...", "otp": "123456", "newPassword": "newpass123" }`
- **Success 200:** `{ "success": true, "message": "Password updated. You can now sign in." }`
- **Errors:** `400 VALIDATION_ERROR` invalid/expired/mismatched code or short password · `404 NOT_FOUND`

### 2. Detections

All endpoints require `Authorization: Bearer <token>`.

#### `GET /api/detections` — Detection history (current user)

- **Success 200:**
  ```json
  {
    "success": true,
    "message": "Detections loaded.",
    "data": {
      "detections": [
        {
          "_id": "6680...",
          "userId": "667f...",
          "modelId": "01",
          "modelName": "dima806/deepfake_vs_real_image_detection",
          "category": "image",
          "fileName": "photo.png",
          "verdict": "AI",
          "confidence": 87.4,
          "resultLabel": "AI Generated (87.4% Confidence)",
          "createdAt": "2026-09-21T08:00:00.000Z",
          "updatedAt": "2026-09-21T08:00:00.000Z"
        }
      ]
    }
  }
  ```
- **Errors:** `401 UNAUTHORIZED`

#### `POST /api/detections` — Save a client-computed result (legacy)

- **Auth:** required
- **Body:**
  ```json
  {
    "modelId": "01", "modelName": "AI Image Detector", "category": "image",
    "fileName": "photo.png", "verdict": "AI", "confidence": 87.4, "resultLabel": "AI Generated"
  }
  ```
- **Success 201:** `{ "success": true, "message": "Detection saved to history.", "detection": {...} }`
- **Errors:** `400 VALIDATION_ERROR` bad verdict · `401 UNAUTHORIZED`

#### `POST /api/detections/analyze` — Full AI detection pipeline ⭐

Uploads a file; the backend forwards it to the **FastAPI ML service**, stores
the result in MongoDB and returns the prediction.

- **Auth:** required
- **Headers:** `Content-Type: multipart/form-data; boundary=...`
- **Form fields:**
  | Field | Type | Required | Notes |
  | --- | --- | --- | --- |
  | `file` | file | yes | Image (max 10 MB) or video (max 50 MB) |
  | `modelId` | string | no | `01` image, `02` face, `03` video, `04` content (default `01`) |

  Supported image types: PNG, JPEG, WEBP, GIF, TIFF, BMP, AVIF.
  Supported video types: MP4, MOV, AVI, MKV, WEBM.
- **Success 201:**
  ```json
  {
    "success": true,
    "message": "Detection completed.",
    "data": {
      "detection": { "id": "6680...", "verdict": "AI", "confidence": 87.4 },
      "prediction": {
        "verdict": "AI",
        "confidence": 87.4,
        "label": "AI Generated",
        "riskLevel": "High"
      }
    }
  }
  ```
- **Errors:**
  - `400 VALIDATION_ERROR` no/empty file · `400 INVALID_FILE_TYPE` bad format
  - `413 FILE_TOO_LARGE`
  - `502 ML_SERVICE_ERROR` upstream failure
  - `503 ML_SERVICE_UNAVAILABLE` / `503 ML_TIMEOUT`
  - `401 UNAUTHORIZED`

#### `DELETE /api/detections/:id` — Delete one detection

- **Auth:** required
- **Success 200:** `{ "success": true, "message": "Detection deleted." }`
- **Errors:** `404 NOT_FOUND` · `401 UNAUTHORIZED`

### 3. User management

All endpoints require `Authorization: Bearer <token>`.

#### `GET /api/user/stats` — XP / level / scan counters

- **Success 200:**
  ```json
  {
    "success": true,
    "message": "Stats loaded.",
    "data": { "stats": { "totalScans": 3, "fakesFound": 2, "cleared": 1, "xp": 30, "level": 1, "xpIntoLevel": 30, "xpForNext": 100 } }
  }
  ```

#### `GET /api/user/premium` — Premium status

- **Success 200:** `{ "data": { "premium": { "active": true, "expiresAt": "2026-10-21..." } } }`

#### `POST /api/user/premium/activate` — Activate 30-day premium

- **Success 200:** `{ "data": { "premium": { "active": true, "expiresAt": "..." } } }`

### 4. Admin APIs

All endpoints require `Authorization: Bearer <adminToken>` where the user's
`isAdmin` flag is `true`.

#### `GET /api/admin/stats/overview` — Global counters

- **Success 200:**
  ```json
  { "data": { "stats": { "totalUsers": 12, "totalDetections": 340, "fakesFound": 210, "cleared": 130, "scansToday": 4 } } }
  ```

#### `GET /api/admin/users?page=1&limit=20` — List users (paginated)

- **Success 200:** `{ "data": { "users": [...], "total": 12, "page": 1, "limit": 20 } }`

#### `GET /api/admin/detections?page=1&limit=20` — List all detections

- **Success 200:** `{ "data": { "detections": [...], "total": 340, "page": 1, "limit": 20 } }`

### 5. Health

#### `GET /api/health`

- **Auth:** none
- **Success 200:**
  ```json
  { "status": "ok", "service": "chitravision-backend", "mlUrlConfigured": true, "nodeEnv": "development" }
  ```

---

## FastAPI ML Service

Base URL: `http://localhost:8000` (dev) / your deployed ML service.

Response envelope: `{ "success": true, "message": "...", "data": {...} }`
Errors: `{ "success": false, "message": "...", "error": { "code": "..." } }`

| Code | Meaning |
| --- | --- |
| `EMPTY_FILE` | Empty upload (422) |
| `FILE_TOO_LARGE` | Over size limit (413) |
| `INVALID_FILE_TYPE` | Unsupported extension (422) |
| `INVALID_IMAGE` | Not a valid image (422) |
| `CORRUPTED_IMAGE` | Decode failed (422) |
| `INVALID_VIDEO` | No readable frames (422) |
| `MODEL_LOAD_ERROR` | Could not load the HuggingFace model (503) |
| `INFERENCE_ERROR` | Model inference failed (502) |
| `MISSING_OPENCV` | Video support not installed (503) |
| `VALIDATION_ERROR` | Malformed request (422) |
| `INTERNAL_ERROR` | Unexpected error (500) |

### `GET /health`

- **Success 200:** `{ "status": "ok", "model": "dima806/deepfake_vs_real_image_detection", "mock": false }`

### `POST /predict/image` — Classify a single image

- **Headers:** `Content-Type: multipart/form-data`
- **Form field:** `file` (PNG / JPEG / WEBP / GIF / TIFF / BMP, max 10 MB)
- **Success 200:**
  ```json
  {
    "success": true,
    "message": "Detection completed.",
    "data": {
      "verdict": "AI",
      "confidence": 87.4,
      "label": "AI Generated",
      "modelName": "dima806/deepfake_vs_real_image_detection",
      "processingMs": 340
    }
  }
  ```

### `POST /predict/video` — Frame-level video classification

- **Form field:** `file` (MP4 / MOV / AVI / MKV / WEBM, max 50 MB, ≤ 120 s by default)
- Frames are sampled with OpenCV (`FRAME_SAMPLE_INTERVAL`) and classified per frame;
  the result is the majority verdict with the mean confidence of the winning class.
- **Success 200:** like `/predict/image` plus `"framesAnalyzed": 120`
- **Errors:** `503 MISSING_OPENCV` · `422 INVALID_VIDEO`

### Environment variables (FastAPI)

| Variable | Default | Purpose |
| --- | --- | --- |
| `MODEL_ID` | `dima806/deepfake_vs_real_image_detection` | HuggingFace model id |
| `HF_TOKEN` | *(empty)* | Read token for gated/private models |
| `MOCK_INFERENCE` | `0` | `1` = deterministic mock (no model download) |
| `MAX_IMAGE_SIZE_MB` | `10` | Image size cap |
| `MAX_VIDEO_SIZE_MB` | `50` | Video size cap |
| `MAX_VIDEO_DURATION_S` | `120` | Video duration cap |
| `FRAME_SAMPLE_INTERVAL` | `30` | Analyze every Nth frame |
| `PORT` / `HOST` | `8000` / `0.0.0.0` | Server bind |

---

## OpenAPI / Swagger

The FastAPI service generates an interactive OpenAPI 3.1 specification:

- Swagger UI: `GET /docs`
- ReDoc: `GET /redoc`
- Raw spec: `GET /openapi.json`

This is auto-generated from the Pydantic models in
`ml_service/app/schemas.py` and the endpoint signatures in
`ml_service/app/predict.py`.

---

## Example: full detection flow

```bash
# 1. Register / login → capture JWT
TOKEN=$(curl -s -X POST http://localhost:4000/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"a@example.com","password":"secret123"}' | python -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")

# 2. Upload an image → backend → FastAPI → HuggingFace → MongoDB
curl -X POST http://localhost:4000/api/detections/analyze \
  -H "Authorization: Bearer $TOKEN" \
  -F "modelId=01" \
  -F "file=@./photo.jpg;type=image/jpeg"
```