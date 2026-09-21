import mongoose from 'mongoose';

const detectionSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
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

export const Detection = mongoose.model('Detection', detectionSchema);