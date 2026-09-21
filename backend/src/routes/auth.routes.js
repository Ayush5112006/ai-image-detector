import { Router } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import crypto from 'node:crypto';

import { User } from '../models/User.model.js';
import { PasswordReset } from '../models/PasswordReset.model.js';
import { authRequired } from '../middleware/auth.js';
import { sendOtpEmail, sendResetOtpEmail } from '../services/email.service.js';

const router = Router();

function signToken(user) {
  return jwt.sign({ sub: user._id.toString() }, process.env.JWT_SECRET, {
    expiresIn: '30d',
  });
}

function sanitize(user) {
  const u = user.toObject();
  delete u.password;
  return u;
}

router.post('/send-otp', async (req, res, next) => {
  try {
    const { email, otp } = req.body || {};
    if (!email || !otp) {
      return res.status(400).json({ message: 'Email and OTP are required' });
    }
    await sendOtpEmail({ toEmail: String(email).trim(), otp: String(otp) });
    res.json({ message: 'OTP sent' });
  } catch (err) {
    console.error('send-otp failed:', err.message);
    res.status(502).json({
      message: `Could not send the verification email: ${err.message}`,
    });
  }
});

router.post('/forgot-password', async (req, res, next) => {
  try {
    const { email } = req.body || {};
    if (!email) {
      return res.status(400).json({ message: 'Email is required' });
    }
    const normalizedEmail = String(email).toLowerCase().trim();
    const user = await User.findOne({ email: normalizedEmail });

    // Respond generically to avoid revealing whether an account exists.
    if (!user) {
      return res.json({
        message:
          'If an account exists for that email, a reset code has been sent.',
      });
    }

    const otp = crypto.randomInt(0, 1000000).toString().padStart(6, '0');
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);
    const otpHash = await bcrypt.hash(otp, 10);

    await PasswordReset.updateMany(
      { email: normalizedEmail, used: false },
      { $set: { used: true } },
    );
    await PasswordReset.create({
      email: normalizedEmail,
      otpHash,
      expiresAt,
    });
    await sendResetOtpEmail({ toEmail: normalizedEmail, otp });

    res.json({
      message:
        'If an account exists for that email, a reset code has been sent.',
    });
  } catch (err) {
    console.error('forgot-password failed:', err.message);
    res
      .status(502)
      .json({ message: `Could not send the reset code: ${err.message}` });
  }
});

router.post('/reset-password', async (req, res, next) => {
  try {
    const { email, otp, newPassword } = req.body || {};
    if (!email || !otp) {
      return res.status(400).json({ message: 'Email and reset code are required' });
    }
    if (!newPassword || String(newPassword).length < 6) {
      return res
        .status(400)
        .json({ message: 'New password must be at least 6 characters' });
    }

    const normalizedEmail = String(email).toLowerCase().trim();
    const reset = await PasswordReset.findOne({
      email: normalizedEmail,
      used: false,
      expiresAt: { $gt: new Date() },
    }).sort({ createdAt: -1 });

    if (!reset) {
      return res
        .status(400)
        .json({ message: 'Invalid or expired code. Please request a new one.' });
    }

    const ok = await bcrypt.compare(String(otp), reset.otpHash);
    if (!ok) {
      return res.status(400).json({ message: 'Invalid reset code.' });
    }

    const user = await User.findOne({ email: normalizedEmail });
    if (!user) {
      return res.status(404).json({ message: 'No account found for this email.' });
    }

    const hashed = await bcrypt.hash(String(newPassword), 10);
    await User.updateOne({ _id: user._id }, { $set: { password: hashed } });
    await PasswordReset.updateOne(
      { _id: reset._id },
      { $set: { used: true } },
    );

    res.json({ message: 'Password updated. You can now sign in.' });
  } catch (err) {
    console.error('reset-password failed:', err.message);
    res.status(500).json({ message: 'Server error. Please try again later.' });
  }
});

router.post('/register', async (req, res, next) => {
  try {
    const { name, email, password } = req.body || {};
    if (!name || !email || !password) {
      return res
        .status(400)
        .json({ message: 'Name, email and password are required' });
    }
    if (String(password).length < 6) {
      return res
        .status(400)
        .json({ message: 'Password must be at least 6 characters' });
    }
    const normalizedEmail = String(email).toLowerCase().trim();
    const existing = await User.findOne({ email: normalizedEmail });
    if (existing) {
      return res
        .status(409)
        .json({ message: 'An account with this email already exists' });
    }
    const hashed = await bcrypt.hash(password, 10);
    const user = await User.create({
      name: String(name).trim(),
      email: normalizedEmail,
      password: hashed,
    });
    res.status(201).json({ token: signToken(user), user: sanitize(user) });
  } catch (err) {
    next(err);
  }
});

router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body || {};
    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }
    const user = await User.findOne({
      email: String(email).toLowerCase().trim(),
    });
    if (!user) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }
    const ok = await bcrypt.compare(String(password), user.password);
    if (!ok) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }
    res.json({ token: signToken(user), user: sanitize(user) });
  } catch (err) {
    next(err);
  }
});

router.get('/me', authRequired, (req, res) => {
  res.json({ user: sanitize(req.user) });
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
      return res.status(400).json({ message: 'Nothing to update' });
    }
    const user = await User.findByIdAndUpdate(req.user._id, updates, {
      new: true,
      runValidators: true,
    }).select('-password');
    res.json({ user });
  } catch (err) {
    next(err);
  }
});

export default router;