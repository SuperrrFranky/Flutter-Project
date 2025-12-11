import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailJSService {
  // Replace with your EmailJS service details
  // Get these from https://www.emailjs.com/ after setting up your account
  static const String serviceId = 'service_azcd67t';
  static const String templateId = 'template_xdhiqqn';
  static const String publicKey = 'GnkhxJT_xVBksHDBe';
  static const String baseUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  static Future<bool> sendVerificationEmail({
    required String toEmail,
    required String verificationCode,
    required String userName,
  }) async {
    try {
      print('=== EmailJS Debug Info ===');
      print('Service ID: $serviceId');
      print('Template ID: $templateId');
      print('Public Key: $publicKey');
      print('To Email: $toEmail');
      print('Verification Code: $verificationCode');
      print('User Name: $userName');
      
      final requestBody = {
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': publicKey,
        'template_params': {
          'to_email': toEmail,
          'user_name': userName,
          'verification_code': verificationCode,
          'message': 'Your verification code is: $verificationCode',
          'from_name': 'Your App Name',
        },
      };
      
      print('Request Body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('=== EmailJS Response ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('Response Headers: ${response.headers}');

      if (response.statusCode == 200) {
        print('✅ Email sent successfully!');
        return true;
      } else {
        print('❌ Email failed with status: ${response.statusCode}');
        print('Error details: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Exception sending email via EmailJS: $e');
      return false;
    }
  }

  /// Test if EmailJS is properly configured
  static bool get isConfigured {
    return serviceId != 'YOUR_SERVICE_ID' && 
           templateId != 'YOUR_TEMPLATE_ID' && 
           publicKey != 'YOUR_PUBLIC_KEY';
  }
}
