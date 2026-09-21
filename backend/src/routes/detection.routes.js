import { Router } from 'express';

import { Detection } from '../models/Detection.model.js';
import { authRequired } from '../middleware/auth.js';

const router = Router();

router.use(authRequired);

router.get('/', async (req, res, next) => {
  try {
    const detections = await Detection.find({ userId: req.user._id }).sort({
      createdAt: -1,
    });
    res.json({ detections });
  } catch (err) {
    next(err);
  }
});

router.post('/', async (req, res, next) => {
  try {
    const {
      modelId = '01',
      modelName = '',
      category = 'image',
      fileName = '',
      verdict,
      confidence = 0,
      resultLabel = '',
    } = req.body || {};

    if (!['AI', 'Real'].includes(verdict)) {
      return res.status(400).json({ message: 'verdict must be "AI" or "Real"' });
    }

    const detection = await Detection.create({
      userId: req.user._id,
      modelId: String(modelId),
      modelName: String(modelName),
      category: String(category),
      fileName: String(fileName),
      verdict,
      confidence: Math.min(100, Math.max(0, Number(confidence) || 0)),
      resultLabel: String(resultLabel),
    });

    await req.user.updateOne({ $inc: { xp: 10 } });

    res.status(201).json({ detection });
  } catch (err) {
    next(err);
  }
});

router.delete('/:id', async (req, res, next) => {
  try {
    const detection = await Detection.findOneAndDelete({
      _id: req.params.id,
      userId: req.user._id,
    });
    if (!detection) {
      return res.status(404).json({ message: 'Detection not found' });
    }
    res.json({ message: 'Detection deleted' });
  } catch (err) {
    next(err);
  }
});

export default router;