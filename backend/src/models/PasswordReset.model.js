import mongoose from 'mongoose';

const passwordResetSchema = new mongoose.Schema(
  {
    email: { type: String, required: true, lowercase: true, trim: true },
    otpHash: { type: String, required: true },
    expiresAt: { type: Date, required: true },
    used: { type: Boolean, default: false },
    purpose: {
      type: String,
      enum: ['password', 'register'],
      default: 'password',
      required: true,
    },
  },
  { timestamps: true },
);

passwordResetSchema.index({ email: 1, purpose: 1, used: 1, createdAt: -1 });

export const PasswordReset = mongoose.model('PasswordReset', passwordResetSchema);