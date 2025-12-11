import 'package:http/http.dart' as http;
import 'dart:convert';

class BackendApiService {
  // TODO: Replace with your actual backend API endpoint
  static const String _baseUrl = 'https://your-backend-api.com/api';
  
  // TODO: Add your API authentication token/headers
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    // 'Authorization': 'Bearer $yourToken',
    // 'X-API-Key': 'your-api-key',
  };

  /// Retrieve original password from backend
  /// This is the key function you need to implement with your backend
  static Future<Map<String, dynamic>> getOriginalPassword(String email) async {
    try {
      // use Firebase's built-in password reset
      // This is the recommended approach for Firebase Auth
      return {
        'success': false,
        'error': 'Use Firebase password reset instead',
        'useFirebaseReset': true,
      };
      
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to connect to backend: $e',
      };
    }
  }

  /// if want to store passwords temporarily in Firestore for testing
  /// This is NOT recommended for production
  static Future<Map<String, dynamic>> getPasswordFromFirestore(String email) async {
    try {
      // This is a fallback method for testing
      // In production, you should use your backend API
      
      // need to import cloud_firestore and implement this
      // aND returning a placeholder
      return {
        'success': false,
        'error': 'Firestore fallback not implemented. Please use backend API.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Firestore error: $e',
      };
    }
  }

  /// Example of how to implement with different backend patterns
  static Future<Map<String, dynamic>> getPasswordWithJWT(String email, String jwtToken) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/user/$email/password'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'originalPassword': data['password'],
          'message': 'Password retrieved successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'Backend API error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to connect to backend: $e',
      };
    }
  }

  /// Example of how to implement with API key authentication
  static Future<Map<String, dynamic>> getPasswordWithApiKey(String email, String apiKey) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/password'),
        headers: {
          ..._headers,
          'X-API-Key': apiKey,
        },
        body: jsonEncode({
          'email': email,
          'request_type': 'password_recovery',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'originalPassword': data['original_password'],
          'message': 'Password retrieved successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'Backend API error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to connect to backend: $e',
      };
    }
  }
}

/// Example backend API implementation (Node.js/Express)
/// 
/// This is what your backend should look like:
/// 
/// ```javascript
/// // Backend API endpoint example
/// app.post('/api/user/password', async (req, res) => {
///   try {
///     const { email, action } = req.body;
///     
///     if (action !== 'get_original_password') {
///       return res.status(400).json({ error: 'Invalid action' });
///     }
///     
///     // Verify the email exists in your database
///     const user = await User.findOne({ email });
///     if (!user) {
///       return res.status(404).json({ error: 'User not found' });
///     }
///     
///     // Return the original password (make sure this is secure!)
///     // In production, you might want to encrypt this or use a different approach
///     res.json({
///       success: true,
///       password: user.originalPassword, // or however you store it
///       message: 'Password retrieved successfully'
///     });
///   } catch (error) {
///     res.status(500).json({ error: 'Internal server error' });
///   }
/// });
/// ```
