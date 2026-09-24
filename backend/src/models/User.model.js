import mongoose from 'mongoose';

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    password: { type: String, required: true },
    phone: { type: String, default: '' },
    location: { type: String, default: '' },
    bio: { type: String, default: '' },
    xp: { type: Number, default: 0 },
    premium: {
      active: { type: Boolean, default: false },
      expiresAt: { type: Date, default: null },
    },
    isAdmin: { type: Boolean, default: false },
    // Rotated by /logout-all (and password reset flows) so every JWT issued
    // before the rotation stops authenticating.
    tokenVersion: { type: Number, default: 0 },
  },
  { timestamps: true },
);

export const User = mongoose.model('User', userSchema);