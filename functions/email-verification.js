const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

// Configure your email service (Gmail, SendGrid, etc.)
const transporter = nodemailer.createTransporter({
  service: 'gmail', // or your preferred service
  auth: {
    user: 'your-email@gmail.com',
    pass: 'your-app-password', // Use app password for Gmail
  },
});

exports.sendVerificationEmail = functions.https.onCall(async (data, context) => {
  const { email, code, userName } = data;

  if (!email || !code || !userName) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
  }

  try {
    const mailOptions = {
      from: 'your-email@gmail.com',
      to: email,
      subject: 'Email Verification Code',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #333;">Email Verification</h2>
          <p>Hello ${userName},</p>
          <p>Your verification code is:</p>
          <div style="background-color: #f4f4f4; padding: 20px; text-align: center; margin: 20px 0;">
            <h1 style="color: #29A87A; font-size: 32px; letter-spacing: 5px; margin: 0;">${code}</h1>
          </div>
          <p>This code will expire in 5 minutes.</p>
          <p>If you didn't request this code, please ignore this email.</p>
        </div>
      `,
    };

    await transporter.sendMail(mailOptions);
    return { success: true };
  } catch (error) {
    console.error('Error sending email:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send email');
  }
});
