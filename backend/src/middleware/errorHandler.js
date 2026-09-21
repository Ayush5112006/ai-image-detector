import { logger } from '../utils/logger.js';
import { AppError, ErrorCodes, sendError } from '../utils/response.js';

/* Centralized Express error handler.
 * Translates framework/library errors into the standardized error envelope
 * and never leaks stack traces, file paths or internals to clients. */
export function notFoundHandler(req, res) {
  return sendError(res, 404, ErrorCodes.NOT_FOUND, 'Not found');
}

export function errorHandler(err, req, res, _next) {
  // Request-ID tagged logging for server-side diagnosis.
  logger.error('request failed', {
    requestId: req.id,
    method: req.method,
    path: req.originalUrl?.split('?')[0],
    auth: req.user?.id ? 'authenticated' : 'anonymous',
    errorType: err?.constructor?.name,
    errorMessage: err?.message,
    code: err?.code,
  });

  // Application error with explicit status/code.
  if (err instanceof AppError) {
    return sendError(res, err.status, err.code, err.message);
  }

  // Multer upload errors.
  if (err?.name === 'MulterError') {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return sendError(res, 413, ErrorCodes.FILE_TOO_LARGE, 'File is too large.');
    }
    return sendError(res, 400, ErrorCodes.VALIDATION, `Upload error: ${err.field ?? 'file'}`);
  }
  if (err?.message === 'Multipart: Boundary not found') {
    return sendError(res, 400, ErrorCodes.VALIDATION, 'Malformed multipart request.');
  }

  // Body parser errors (invalid JSON payload too large).
  if (err?.type === 'entity.too.large') {
    return sendError(res, 413, ErrorCodes.FILE_TOO_LARGE, 'Request body is too large.');
  }
  if (err?.type === 'entity.parse.failed') {
    return sendError(res, 400, ErrorCodes.VALIDATION, 'Request body is not valid JSON.');
  }

  // Mongoose errors.
  if (err?.name === 'ValidationError') {
    const first = Object.values(err.errors ?? {})[0];
    return sendError(
      res,
      422,
      ErrorCodes.VALIDATION,
      first?.message ?? 'Validation failed.',
    );
  }
  if (err?.name === 'CastError') {
    return sendError(res, 400, ErrorCodes.VALIDATION, 'Invalid identifier in request.');
  }
  if (err?.code === 11000) {
    return sendError(res, 409, ErrorCodes.CONFLICT, 'A record with that value already exists.');
  }

  // Unknown error — never leak internals.
  return sendError(res, 500, ErrorCodes.INTERNAL, 'An unexpected error occurred.');
}