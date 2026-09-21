/* Shared HTTP response helpers.
 *
 * Success shape:
 *   { "success": true, "message": "...", ...payload }
 * The payload is spread at the top level so existing clients that read
 * `token`, `user`, `detection`, `detections` etc. keep working while the
 * standardized envelope stays consistent.
 *
 * Error shape:
 *   { "success": false, "message": "...", "error": { "code": "..." } }
 */

export class AppError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
    this.expose = true;
  }
}

export function sendSuccess(res, message, payload = {}, status = 200) {
  return res.status(status).json({ success: true, message, ...payload });
}

export function sendCreated(res, message, payload = {}) {
  return sendSuccess(res, message, payload, 201);
}

export function sendError(res, status, code, message) {
  return res.status(status).json({
    success: false,
    message,
    error: { code },
  });
}

/** Error codes used across the API. */
export const ErrorCodes = {
  VALIDATION: 'VALIDATION_ERROR',
  UNAUTHORIZED: 'UNAUTHORIZED',
  FORBIDDEN: 'FORBIDDEN',
  NOT_FOUND: 'NOT_FOUND',
  CONFLICT: 'CONFLICT',
  FILE_TOO_LARGE: 'FILE_TOO_LARGE',
  INVALID_FILE_TYPE: 'INVALID_FILE_TYPE',
  ML_SERVICE_UNAVAILABLE: 'ML_SERVICE_UNAVAILABLE',
  ML_TIMEOUT: 'ML_TIMEOUT',
  ML_SERVICE_ERROR: 'ML_SERVICE_ERROR',
  EMAIL_ERROR: 'EMAIL_ERROR',
  INTERNAL: 'INTERNAL_ERROR',
};