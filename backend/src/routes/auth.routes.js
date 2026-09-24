import { Router } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import crypto from 'node:crypto';

import { User } from '../models/User.model.js';
import { PasswordReset } from '../models/PasswordReset.model.js';
import { Detection } from '../models/Detection.model.js';
import { authRequired } from '../middleware/auth.js';
import {
  sendOtpEmail,
  sendResetOtpEmail,
  sendWelcomeEmail,
  sendPasswordChangedEmail,
} from '../services/email.service.js';
import { sendSuccess, sendError, ErrorCodes, sendCreated } from '../utils/response.js';
import { logger } from '../utils/logger.js';

const router = Router();

function signToken(user) {
  return jwt.sign(
    { sub: user._id.toString(), ver: user.tokenVersion ?? 0 },
    process.env.JWT_SECRET,
    { expiresIn: '30d' },
  );
}

function sanitize(user) {
  const u = user.toObject();
  delete u.password;
  return u;
}

function generateOtp() {
  return crypto.randomInt(0, 1000000).toString().padStart(6, '0');
}

async function storeOtp(email, purpose, ttlMinutes) {
  const otp = generateOtp();
  const expiresAt = new Date(Date.now() + ttlMinutes * 60 * 1000);
  const otpHash = await bcrypt.hash(otp, 10);
  await PasswordReset.updateMany(
    { email, purpose, used: false },
    { $set: { used: true } },
  );
  await PasswordReset.create({ email, purpose, otpHash, expiresAt });
  return otp;
}

router.post('/send-otp', async (req, res, next) => {
  const { email } = req.body || {};
  if (!email || !String(email).trim()) {
    return sendError(res, 400, ErrorCodes.VALIDATION, 'Email is required');
  }
  try {
    // The OTP is generated and stored server-side; the client only receives
    // a delivery receipt. It must be passed back to /register to complete
    // account creation.
    const normalizedEmail = String(email).toLowerCase().trim();
    const otp = await storeOtp(normalizedEmail, 'register', 5);
    await sendOtpEmail({ toEmail: normalizedEmail, otp });
    return sendSuccess(res, 'OTP sent');
  } catch (err) {
    return sendError(
      res, 502, ErrorCodes.EMAIL_ERROR,
      'Could not send the verification email. Please try again later.',
    );
  }
});

router.post('/forgot-password', async (req, res, next) => {
  try {
    const { email } = req.body || {};
    if (!email) {
      return sendError(res, 400, ErrorCodes.VALIDATION, 'Email is required');
    }
    const normalizedEmail = String(email).toLowerCase().trim();
    const user = await User.findOne({ email: normalizedEmail });

    // Respond generically to avoid revealing whether an account exists.
    const genericMessage =
      'If an account exists for that email, a reset code has been sent.';
    if (!user) {
      return sendSuccess(res, genericMessage, { message: genericMessage });
    }

    const otp = await storeOtp(normalizedEmail, 'password', 10);
    try {
      await sendResetOtpEmail({ toEmail: normalizedEmail, otp });
    } catch (err) {
      return sendError(
        res, 502, ErrorCodes.EMAIL_ERROR,
        'Could not send the reset code. Please try again later.',
      );
    }

    return sendSuccess(res, genericMessage, { message: genericMessage });
  } catch (err) {
    next(err);
  }
});

router.post('/reset-password', async (req, res, next) => {
  try {
    const { email, otp, newPassword } = req.body || {};
    if (!email || !otp) {
      return sendError(res, 400, ErrorCodes.VALIDATION, 'Email and reset code are required');
    }
    if (!newPassword || String(newPassword).length < 6) {
      return sendError(
        res, 400, ErrorCodes.VALIDATION,
        'New password must be at least 6 characters',
      );
    }

    const normalizedEmail = String(email).toLowerCase().trim();
    const reset = await PasswordReset.findOne({
      email: normalizedEmail,
      purpose: 'password',
      used: false,
      expiresAt: { $gt: new Date() },
    }).sort({ createdAt: -1 });

    if (!reset) {
      return sendError(
        res, 400, ErrorCodes.VALIDATION,
        'Invalid or expired code. Please request a new one.',
      );
    }

    const ok = await bcrypt.compare(String(otp), reset.otpHash);
    if (!ok) {
      return sendError(res, 400, ErrorCodes.VALIDATION, 'Invalid reset code.');
    }

    const user = await User.findOne({ email: normalizedEmail });
    if (!user) {
      return sendError(res, 404, ErrorCodes.NOT_FOUND, 'No account found for this email.');
    }

    const hashed = await bcrypt.hash(String(newPassword), 10);
    await User.updateOne({ _id: user._id }, { $set: { password: hashed } });
    await PasswordReset.updateOne(
      { _id: reset._id },
      { $set: { used: true } },
    );

    sendPasswordChangedEmail({
      toEmail: normalizedEmail,
      name: user.name,
    }).then(() => {
      logger.info('password-changed email sent', { userId: user._id.toString() });
    }).catch((err) => {
      logger.warn('password-changed email failed', { userId: user._id.toString(), error: err.message });
    });

    return sendSuccess(res, 'Password updated. You can now sign in.');
  } catch (err) {
    next(err);
  }
});

router.post('/register', async (req, res, next) => {
  try {
    const { name, email, password, otp } = req.body || {};
    if (!name || !email || !password || !otp) {
      return sendError(
        res, 400, ErrorCodes.VALIDATION,
        'Name, email, password and verification code are required',
      );
    }
    if (String(password).length < 6) {
      return sendError(res, 400, ErrorCodes.VALIDATION, 'Password must be at least 6 characters');
    }
    const normalizedEmail = String(email).toLowerCase().trim();
    const existing = await User.findOne({ email: normalizedEmail });
    if (existing) {
      return sendError(res, 409, ErrorCodes.CONFLICT, 'An account with this email already exists');
    }
    const reset = await PasswordReset.findOne({
      email: normalizedEmail,
      purpose: 'register',
      used: false,
      expiresAt: { $gt: new Date() },
    }).sort({ createdAt: -1 });
    if (!reset) {
      return sendError(
        res, 400, ErrorCodes.VALIDATION,
        'Invalid or expired verification code. Please request a new one.',
      );
    }
    const okOtp = await bcrypt.compare(String(otp).trim(), reset.otpHash);
    if (!okOtp) {
      return sendError(res, 400, ErrorCodes.VALIDATION, 'Invalid verification code.');
    }
    const hashed = await bcrypt.hash(password, 10);
    const user = await User.create({
      name: String(name).trim(),
      email: normalizedEmail,
      password: hashed,
    });
    await PasswordReset.updateOne(
      { _id: reset._id },
      { $set: { used: true } },
    );
    sendWelcomeEmail({
      toEmail: normalizedEmail,
      name: user.name,
    }).then(() => {
      logger.info('welcome email sent', { userId: user._id.toString() });
    }).catch((err) => {
      logger.warn('welcome email failed', { userId: user._id.toString(), error: err.message });
    });
    return sendCreated(
      res,
      'Account created successfully.',
      { token: signToken(user), user: sanitize(user) },
    );
  } catch (err) {
    next(err);
  }
});

router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body || {};
    if (!email || !password) {
      return sendError(res, 400, ErrorCodes.VALIDATION, 'Email and password are required');
    }
    const user = await User.findOne({ email: String(email).toLowerCase().trim() });
    if (!user) {
      return sendError(res, 401, ErrorCodes.UNAUTHORIZED, 'Invalid email or password');
    }
    const ok = await bcrypt.compare(String(password), user.password);
    if (!ok) {
      return sendError(res, 401, ErrorCodes.UNAUTHORIZED, 'Invalid email or password');
    }
    return sendSuccess(res, 'Signed in successfully.', {
      token: signToken(user),
      user: sanitize(user),
    });
  } catch (err) {
    next(err);
  }
});

router.get('/me', authRequired, (req, res) => {
  sendSuccess(res, 'Profile loaded.', { user: sanitize(req.user) });
});

router.patch('/me', authRequired, async (req, res, next) => {
  try {
    const allowed = ['name', 'phone', 'location', 'bio'];
    const updates = {};
    for (const field of allowed) {
      if (req.body?.[field] !== undefined) {
        updates[field] = String(req.body[field]).trim();
      }
    }
    if (Object.keys(updates).length === 0) {
      return sendError(res, 400, ErrorCodes.VALIDATION, 'Nothing to update');
    }
    const user = await User.findByIdAndUpdate(req.user._id, updates, {
      new: true,
      runValidators: true,
    }).select('-password');
    return sendSuccess(res, 'Profile updated.', { user });
  } catch (err) {
    next(err);
  }
});

router.post('/change-password', authRequired, async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body || {};
    if (!currentPassword || !newPassword) {
      return sendError(
        res, 400, ErrorCodes.VALIDATION,
        'Current and new password are required',
      );
    }
    if (String(newPassword).length < 6) {
      return sendError(
        res, 400, ErrorCodes.VALIDATION,
        'New password must be at least 6 characters',
      );
    }
    const user = await User.findById(req.user._id).select('+password');
    const ok = await bcrypt.compare(String(currentPassword), user.password);
    if (!ok) {
      return sendError(
        res, 400, ErrorCodes.VALIDATION,
        'Current password is incorrect.',
      );
    }
    const hashed = await bcrypt.hash(String(newPassword), 10);
    await User.updateOne({ _id: user._id }, { $set: { password: hashed } });

    sendPasswordChangedEmail({
      toEmail: user.email,
      name: user.name,
    }).then(() => {
      logger.info('password-changed email sent', { userId: user._id.toString() });
    }).catch((err) => {
      logger.warn('password-changed email failed', { userId: user._id.toString(), error: err.message });
    });

    return sendSuccess(res, 'Password updated successfully.');
  } catch (err) {
    next(err);
  }
});

router.post('/logout-all', authRequired, async (req, res, next) => {
  try {
    // Rotating tokenVersion invalidates every existing JWT, then we re-issue
    // a fresh one bound to the new version so the current device stays signed in.
    const user = await User.findByIdAndUpdate(
      req.user._id,
      { $inc: { tokenVersion: 1 } },
      { new: true },
    );
    return sendSuccess(res, 'Signed out of all other devices.', {
      token: signToken(user),
    });
  } catch (err) {
    next(err);
  }
});

router.delete('/me', authRequired, async (req, res, next) => {
  try {
    await Detection.deleteMany({ userId: req.user._id });
    await PasswordReset.deleteMany({ email: req.user.email });
    await User.deleteOne({ _id: req.user._id });
    return sendSuccess(res, 'Account and all associated data deleted.');
  } catch (err) {
    next(err);
  }
});

export default router;