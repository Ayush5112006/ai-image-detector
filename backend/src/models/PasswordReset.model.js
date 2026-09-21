import mongoose from 'mongoose';

const passwordResetSchema = new mongoose.Schema(
  {
    email: { type: String, required: true, lowercase: true, trim: true },
    otpHash: { type: String, required: true },
    expiresAt: { type: Date, required: true },
    used: { type: Boolean, default: false },
  },
  { timestamps: true },
);

passwordResetSchema.index({ email: 1, used: 1, expiresAt: 1 });

export const PasswordReset = mongoose.model('PasswordReset', passwordResetSchema);