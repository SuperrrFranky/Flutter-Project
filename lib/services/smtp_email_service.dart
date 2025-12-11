import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class SMTPEmailService {
  // Configure your SMTP server settings for Gmail
  static const String smtpServer = 'smtp.gmail.com';
  static const int smtpPort = 587;
  static const String username = 'shekjunyi@gmail.com'; // Replace with your Gmail
  static const String password = 'fffwalejstfmfscy'; // Replace with your Gmail password

  /// Test if SMTP is properly configured
  static bool get isConfigured {
    return username != 'your-personal-gmail@gmail.com' && 
           password != 'your-16-char-app-password' &&
           username.contains('@gmail.com') &&
           password.length >= 16; // Gmail App Password is 16 characters
  }

  /// Test SMTP configuration
  static void printConfigurationStatus() {
    print('=== SMTP Configuration Status ===');
    print('Username: $username');
    print('Password length: ${password.length}');
    print('Is configured: $isConfigured');
    print('===============================');
  }

  static Future<bool> sendVerificationEmail({
    required String toEmail,
    required String verificationCode,
    required String userName,
  }) async {
    try {
      print('=== SMTP Email Debug Info ===');
      print('SMTP Server: $smtpServer:$smtpPort');
      print('Username: $username');
      print('To Email: $toEmail');
      print('Verification Code: $verificationCode');
      print('User Name: $userName');

      if (!isConfigured) {
        print('❌ SMTP not configured - please update credentials');
        return false;
      }

      // Create SMTP server for Gmail
      final smtpServerConfig = SmtpServer(
        smtpServer,
        port: smtpPort,
        username: username,
        password: password,
        allowInsecure: false,
        ssl: false,
        ignoreBadCertificate: false,
      );

      // Create email message
      final message = Message()
        ..from = Address(username, 'Your App Name')
        ..recipients.add(toEmail)
        ..subject = 'Email Verification Code'
        ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <h2 style="color: #29A87A;">Email Verification</h2>
            <p>Hello $userName,</p>
            <p>Your verification code is:</p>
            <div style="background-color: #f4f4f4; padding: 20px; text-align: center; margin: 20px 0; border-radius: 8px;">
              <h1 style="color: #29A87A; font-size: 32px; letter-spacing: 5px; margin: 0;">$verificationCode</h1>
            </div>
            <p>This code will expire in 5 minutes.</p>
            <p>If you didn't request this code, please ignore this email.</p>
            <hr style="margin: 20px 0; border: none; border-top: 1px solid #eee;">
            <p style="color: #666; font-size: 12px;">Best regards,<br>Your App Name</p>
          </div>
        ''';

      print('Sending email via SMTP...');
      
      // Send email
      final sendReport = await send(message, smtpServerConfig);
      
      print('✅ Email sent successfully via SMTP!');
      print('Send Report: $sendReport');
      
      return true;
    } catch (e) {
      print('❌ Error sending email via SMTP: $e');
      print('Error type: ${e.runtimeType}');
      return false;
    }
  }
}
