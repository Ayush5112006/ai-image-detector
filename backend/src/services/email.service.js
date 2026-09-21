import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.SENDER_EMAIL,
    pass: process.env.SENDER_APP_PASSWORD,
  },
});

const APP_NAME = 'ChitraVision AI';

export async function sendWelcomeEmail({ toEmail, name }) {
  const displayName = String(name || 'there').trim();
  const html = `
  <div style="font-family: Arial, sans-serif; max-width: 420px; margin: 0 auto; color: #1F2937;">
    <h2 style="color: #007AFF; margin-bottom: 8px;">${APP_NAME}</h2>
    <p>Dear ${displayName},</p>
    <p><strong>Welcome to ${APP_NAME}.</strong></p>
    <p>We're excited to have you with us.</p>
    <p>
      Your account has been <strong>successfully created and securely activated</strong>.
      You're now ready to explore a smarter way to analyze digital content and make
      more informed decisions about what you see online.
    </p>

    <h3 style="color: #111827; margin-top: 24px;">Your Account Is Ready</h3>
    <div style="background: #EFF4FB; border-radius: 10px; padding: 14px 20px; font-size: 14px;">
      <p style="margin: 6px 0;"><strong>Account Status</strong>&nbsp;&nbsp;<span style="color: #16A34A;">● Active</span></p>
      <p style="margin: 6px 0;"><strong>Registration</strong>&nbsp;&nbsp;<span style="color: #16A34A;">✓ Verified</span></p>
      <p style="margin: 6px 0;"><strong>Platform Access</strong>&nbsp;&nbsp;<span style="color: #16A34A;">✓ Enabled</span></p>
    </div>

    <p style="margin-top: 20px;">
      From this moment forward, you can use ${APP_NAME} to
      <strong>analyze, verify, and understand digital content</strong> with confidence.
    </p>
    <p>
      Whether you're checking an image, analyzing a video, or reviewing your previous
      results, everything you need is now just a few taps away.
    </p>

    <h3 style="color: #111827; margin-top: 24px;">Your next step</h3>
    <p><strong>Sign in to ${APP_NAME} and start your first detection.</strong></p>
    <blockquote style="border-left: 4px solid #007AFF; margin: 16px 0; padding-left: 12px; color: #374151;">
      Don't just see it. Verify it.
    </blockquote>

    <p>Thank you for choosing <strong>${APP_NAME}</strong> and becoming part of our community.</p>
    <p>Stay informed. Stay secure.</p>
    <p style="font-weight: bold; margin-bottom: 4px;">The ${APP_NAME} Team</p>
    <p style="color: #9CA3AF; font-size: 12px; margin-top: 0;">AI-powered digital content verification</p>
    <p style="color: #9CA3AF; font-size: 12px;">If you did not create this account, you can safely ignore this email.</p>
  </div>
  `;

  const info = await transporter.sendMail({
    from: `"${APP_NAME}" <${process.env.SENDER_EMAIL}>`,
    to: toEmail,
    subject: `Welcome to ${APP_NAME}, ${displayName}!`,
    text: `Dear ${displayName},\n\nWelcome to ${APP_NAME}.\n\nWe're excited to have you with us. Your account has been successfully created and securely activated.\n\nAccount Status: Active\nRegistration: Verified\nPlatform Access: Enabled\n\nSign in to ${APP_NAME} and start your first detection.\n\nDon't just see it. Verify it.\n\nThank you for choosing ${APP_NAME} and becoming part of our community.\n\nStay informed. Stay secure.\nThe ${APP_NAME} Team`,
    html,
  });

  return info;
}

export async function sendOtpEmail({ toEmail, otp }) {
  const html = `
  <div style="font-family: Arial, sans-serif; max-width: 420px; margin: 0 auto;">
    <h2 style="color: #007AFF; margin-bottom: 8px;">${APP_NAME}</h2>
    <p style="color: #1F2937;">Your verification code is:</p>
    <div style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #1F2937; background: #EFF4FB; border-radius: 10px; padding: 14px 20px; display: inline-block;">
      ${otp}
    </div>
    <p style="color: #6B7280; margin-top: 16px;">
      Enter this code in the app to finish creating your account. This code expires in 5 minutes.
    </p>
    <p style="color: #9CA3AF; font-size: 12px;">If you did not request this code, you can safely ignore this email.</p>
  </div>
  `;

  const info = await transporter.sendMail({
    from: `"${APP_NAME}" <${process.env.SENDER_EMAIL}>`,
    to: toEmail,
    subject: 'ChitraVision Verification Code',
    text: `Your ChitraVision verification code is ${otp}. Enter this code in the app to finish creating your account.`,
    html,
  });

  return info;
}

export async function sendResetOtpEmail({ toEmail, otp }) {
  const html = `
  <div style="font-family: Arial, sans-serif; max-width: 420px; margin: 0 auto;">
    <h2 style="color: #007AFF; margin-bottom: 8px;">${APP_NAME}</h2>
    <p style="color: #1F2937;">We received a request to reset your password. Use this code to create a new one:</p>
    <div style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #1F2937; background: #EFF4FB; border-radius: 10px; padding: 14px 20px; display: inline-block;">
      ${otp}
    </div>
    <p style="color: #6B7280; margin-top: 16px;">
      Enter this code in the app to reset your password. It expires in 10 minutes.
    </p>
    <p style="color: #9CA3AF; font-size: 12px;">If you did not request a password reset, you can safely ignore this email.</p>
  </div>
  `;

  const info = await transporter.sendMail({
    from: `"${APP_NAME}" <${process.env.SENDER_EMAIL}>`,
    to: toEmail,
    subject: 'ChitraVision Password Reset Code',
    text: `Your ChitraVision password reset code is ${otp}. Enter it in the app to reset your password. It expires in 10 minutes.`,
    html,
  });

  return info;
}

export async function sendPasswordChangedEmail({ toEmail, name }) {
  const displayName = String(name || 'there').trim();
  const html = `
  <div style="font-family: Arial, sans-serif; max-width: 420px; margin: 0 auto; color: #1F2937;">
    <h2 style="color: #007AFF; margin-bottom: 8px;">${APP_NAME}</h2>
    <p>Dear ${displayName},</p>
    <p>Your password has been <strong>successfully changed</strong>.</p>
    <p>You can now sign in to ${APP_NAME} with your new password and continue analyzing digital content.</p>

    <h3 style="color: #111827; margin-top: 24px;">Security reminder</h3>
    <div style="background: #EFF4FB; border-radius: 10px; padding: 14px 20px; font-size: 14px;">
      <p style="margin: 6px 0;">&#128274; Never share your password with anyone.</p>
      <p style="margin: 6px 0;">&#128274; Use a strong, unique password for your account.</p>
    </div>

    <p style="margin-top: 20px;">
      If you did not make this change, please contact our support team immediately
      and consider resetting your password again.
    </p>

    <p>Stay informed. Stay secure.</p>
    <p style="font-weight: bold; margin-bottom: 4px;">The ${APP_NAME} Team</p>
  </div>
  `;

  const info = await transporter.sendMail({
    from: `"${APP_NAME}" <${process.env.SENDER_EMAIL}>`,
    to: toEmail,
    subject: `Your ${APP_NAME} Password Has Been Changed`,
    text: `Dear ${displayName},\n\nYour password has been successfully changed. You can now sign in to ${APP_NAME} with your new password.\n\nIf you did not make this change, please contact support immediately.\n\nStay informed. Stay secure.\nThe ${APP_NAME} Team`,
    html,
  });

  return info;
}