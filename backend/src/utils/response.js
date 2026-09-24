/* Shared HTTP response helpers.
 *
 * Standardized envelope (consistent across the whole API):
 *   Success: { "success": true, "message": "...", "data": { ... } }
 *   Error:   { "success": false, "message": "...", "error": { "code": "..." } }
 *
 * All payload fields are wrapped under a single `data` key so clients have a
 * stable way to read the result regardless of which resource was queried.
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
  return res.status(status).json({ success: true, message, data: payload });
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