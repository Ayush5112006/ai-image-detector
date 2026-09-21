import mongoose from 'mongoose';

const detectionSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    modelId: { type: String, required: true },
    modelName: { type: String, default: '' },
    category: {
      type: String,
      enum: ['image', 'face', 'video', 'content'],
      default: 'image',
    },
    fileName: { type: String, default: '' },
    verdict: { type: String, enum: ['AI', 'Real'], required: true },
    confidence: { type: Number, min: 0, max: 100, default: 0 },
    resultLabel: { type: String, default: '' },
  },
  { timestamps: true },
);

// Composite indexes targeted at the two hottest queries:
//  1. history screen — a user's detections, newest first
//  2. stats screen   — counts per user grouped by verdict
detectionSchema.index({ userId: 1, createdAt: -1 });
detectionSchema.index({ userId: 1, verdict: 1 });

export const Detection = mongoose.model('Detection', detectionSchema);