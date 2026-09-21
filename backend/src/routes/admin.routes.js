import { Router } from 'express';

import { User } from '../models/User.model.js';
import { Detection } from '../models/Detection.model.js';
import { requireAdmin } from '../middleware/auth.js';
import { sendSuccess } from '../utils/response.js';

const router = Router();

router.use(requireAdmin);

router.get('/stats/overview', async (req, res, next) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const [totalUsers, totalDetections, fakesFound, cleared, scansToday] =
      await Promise.all([
        User.countDocuments({}),
        Detection.countDocuments({}),
        Detection.countDocuments({ verdict: 'AI' }),
        Detection.countDocuments({ verdict: 'Real' }),
        Detection.countDocuments({ createdAt: { $gte: today } }),
      ]);
    return sendSuccess(res, 'Admin overview loaded.', {
      stats: { totalUsers, totalDetections, fakesFound, cleared, scansToday },
    });
  } catch (err) {
    next(err);
  }
});

router.get('/users', async (req, res, next) => {
  try {
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(req.query.limit) || 20));
    const [users, total] = await Promise.all([
      User.find({})
        .select('-password')
        .sort({ createdAt: -1 })
        .skip((page - 1) * limit)
        .limit(limit),
      User.countDocuments({}),
    ]);
    return sendSuccess(res, 'Users loaded.', { users, total, page, limit });
  } catch (err) {
    next(err);
  }
});

router.get('/detections', async (req, res, next) => {
  try {
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(req.query.limit) || 20));
    const [detections, total] = await Promise.all([
      Detection.find({})
        .sort({ createdAt: -1 })
        .skip((page - 1) * limit)
        .limit(limit),
      Detection.countDocuments({}),
    ]);
    return sendSuccess(res, 'Detections loaded.', { detections, total, page, limit });
  } catch (err) {
    next(err);
  }
});

export default router;