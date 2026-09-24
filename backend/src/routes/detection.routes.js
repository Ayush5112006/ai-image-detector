import { Router } from 'express';

import { Detection } from '../models/Detection.model.js';
import { authRequired } from '../middleware/auth.js';
import { uploadMedia, validateMediaSize } from '../middleware/upload.js';
import { analyzeMedia } from '../services/mlClient.service.js';
import { sendSuccess, sendError, ErrorCodes, sendCreated } from '../utils/response.js';
import { logger } from '../utils/logger.js';

const router = Router();

function categoryForModel(modelId) {
  switch (String(modelId || '01')) {
    case '02': return 'face';
    case '03': return 'video';
    case '04': return 'content';
    default: return 'image';
  }
}

router.use(authRequired);

// List the current user's detections, newest first.
router.get('/', async (req, res, next) => {
  try {
    const detections = await Detection.find({ userId: req.user._id }).sort({
      createdAt: -1,
    });
    return sendSuccess(res, 'Detections loaded.', { detections });
  } catch (err) {
    next(err);
  }
});

// Full pipeline: upload media -> FastAPI -> HuggingFace -> MongoDB.
// Expects multipart/form-data with a `file` field and an optional `modelId`.
router.post('/analyze', uploadMedia.single('file'), async (req, res, next) => {
  try {
    if (!req.file) {
      return sendError(res, 400, ErrorCodes.VALIDATION, 'No file was uploaded.');
    }
    if (req.file.size === 0) {
      return sendError(res, 400, ErrorCodes.VALIDATION, 'The uploaded file is empty.');
    }
    const sizeError = validateMediaSize(req.file);
    if (sizeError) {
      return sendError(res, sizeError.status, sizeError.code, sizeError.message);
    }

    const modelId = String(req.body?.modelId || '01');
    const category = categoryForModel(modelId);
    const loggerMeta = { requestId: req.id, filename: req.file.originalname, mediaType: category };

    logger.info('detection started', loggerMeta);
    logger.info('file validation completed', {
      requestId: req.id,
      size: req.file.size,
      mimetype: req.file.mimetype,
    });

    const result = await analyzeMedia({
      bytes: req.file.buffer,
      filename: req.file.originalname,
      mimetype: req.file.mimetype,
      requestId: req.id,
    });

    const detection = await Detection.create({
      userId: req.user._id,
      modelId,
      modelName: result.modelName || 'dima806/deepfake_vs_real_image_detection',
      category,
      fileName: req.file.originalname,
      verdict: result.verdict,
      confidence: Math.min(100, Math.max(0, Number(result.confidence) || 0)),
      resultLabel: `${result.label} (${result.confidence}% Confidence)`,
    });

    await req.user.updateOne({ $inc: { xp: 10 } });
    logger.info('detection completed', {
      requestId: req.id,
      detectionId: detection._id,
      verdict: detection.verdict,
      durationMs: Date.now() - req._startedAt,
    });

    return sendCreated(res, 'Detection completed.', {
      detection,
      prediction: {
        verdict: detection.verdict,
        confidence: detection.confidence,
        label: result.label,
        riskLevel: detection.verdict === 'AI'
          ? (detection.confidence >= 80 ? 'High' : detection.confidence >= 60 ? 'Medium' : 'Low')
          : 'None',
      },
    });
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
      return sendError(res, 404, ErrorCodes.NOT_FOUND, 'Detection not found');
    }
    return sendSuccess(res, 'Detection deleted.');
  } catch (err) {
    next(err);
  }
});

export default router;