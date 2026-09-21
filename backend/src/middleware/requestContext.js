import crypto from 'node:crypto';
import { logger } from '../utils/logger.js';

// Attaches a request id and logs every request with its duration.
export function requestContext(req, _res, next) {
  req.id = req.headers['x-request-id'] || crypto.randomUUID();
  req._startedAt = Date.now();
  _res.on('finish', () => {
    const duration = Date.now() - req._startedAt;
    const level = _res.statusCode >= 500 ? 'error' : _res.statusCode >= 400 ? 'warn' : 'info';
    logger[level]('request completed', {
      requestId: req.id,
      method: req.method,
      path: req.originalUrl.split('?')[0],
      status: _res.statusCode,
      durationMs: duration,
      auth: req.user?.id ? 'authenticated' : 'anonymous',
    });
  });
  next();
}