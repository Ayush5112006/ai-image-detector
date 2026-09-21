import jwt from 'jsonwebtoken';
import { User } from '../models/User.model.js';
import { sendError, ErrorCodes } from '../utils/response.js';

export async function authRequired(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) {
      return sendError(res, 401, ErrorCodes.UNAUTHORIZED, 'Not authenticated');
    }
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(payload.sub).select('-password');
    if (!user) {
      return sendError(res, 401, ErrorCodes.UNAUTHORIZED, 'User no longer exists');
    }
    req.user = user;
    next();
  } catch {
    sendError(res, 401, ErrorCodes.UNAUTHORIZED, 'Invalid or expired session');
  }
}

export async function requireAdmin(req, res, next) {
  await authRequired(req, res, () => {
    if (req.user?.isAdmin !== true) {
      return sendError(res, 403, ErrorCodes.FORBIDDEN, 'Admin access required');
    }
    next();
  });
}