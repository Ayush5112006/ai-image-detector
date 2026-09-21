import { Router } from 'express';

import { Detection } from '../models/Detection.model.js';
import { authRequired } from '../middleware/auth.js';
import { sendSuccess } from '../utils/response.js';

const router = Router();

router.use(authRequired);

router.get('/stats', async (req, res, next) => {
  try {
    const [totalScans, fakesFound, cleared] = await Promise.all([
      Detection.countDocuments({ userId: req.user._id }),
      Detection.countDocuments({ userId: req.user._id, verdict: 'AI' }),
      Detection.countDocuments({ userId: req.user._id, verdict: 'Real' }),
    ]);
    const xp = req.user.xp || 0;
    const level = Math.floor(xp / 100) + 1;
    return sendSuccess(res, 'Stats loaded.', {
      stats: {
        totalScans,
        fakesFound,
        cleared,
        xp,
        level,
        xpIntoLevel: xp % 100,
        xpForNext: 100,
      },
    });
  } catch (err) {
    next(err);
  }
});

router.get('/premium', (req, res) => {
  const { active, expiresAt } = req.user.premium || {};
  const isActive = Boolean(active) && (!expiresAt || new Date(expiresAt) > new Date());
  return sendSuccess(res, 'Premium status loaded.', {
    premium: { active: isActive, expiresAt: expiresAt || null },
  });
});

router.post('/premium/activate', async (req, res, next) => {
  try {
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    await req.user.updateOne({ $set: { premium: { active: true, expiresAt } } });
    return sendSuccess(res, 'Premium activated.', { premium: { active: true, expiresAt } });
  } catch (err) {
    next(err);
  }
});

export default router;