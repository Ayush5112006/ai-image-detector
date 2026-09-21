import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.SENDER_EMAIL,
    pass: process.env.SENDER_APP_PASSWORD,
  },
});

const APP_NAME = 'ChitraVision AI';

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