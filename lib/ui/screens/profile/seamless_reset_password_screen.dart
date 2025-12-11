import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/email_verification_service.dart';
import '../../../services/password_recovery_service.dart';

class SeamlessResetPasswordScreen extends StatefulWidget {
  final String email;
  final bool isFromChangePassword;

  const SeamlessResetPasswordScreen({
    super.key,
    required this.email,
    this.isFromChangePassword = false,
  });

  @override
  State<SeamlessResetPasswordScreen> createState() => _SeamlessResetPasswordScreenState();
}

class _SeamlessResetPasswordScreenState extends State<SeamlessResetPasswordScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isResending = false;
  bool _isVerifying = false;
  bool _isChangingPassword = false;
  bool _emailVerified = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _emailVerified ? 'Set New Password' : 'Verify Your Email',
          style: const TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _emailVerified ? 'Set Your New Password' : 'Verify Your Email',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _emailVerified 
                          ? 'Enter your new password below'
                          : 'We sent a 6-digit verification code to:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (!_emailVerified) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.email,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.app_green,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      _emailVerified
                          ? 'Your email has been verified. Now you can set a new password for your account.'
                          : 'Enter the code below to verify your email, then we\'ll help you set a new password.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              if (!_emailVerified) ...[
                // Verification Code Input
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verification Code',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) {
                          return SizedBox(
                            width: 45,
                            height: 55,
                            child: TextFormField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) => _onDigitChanged(value, index),
                              decoration: InputDecoration(
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AppColors.app_green, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      
                      // Resend Code Button
                      Center(
                        child: TextButton(
                          onPressed: _isResending ? null : _resendCode,
                          child: _isResending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: AppColors.app_green,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Resend Code',
                                  style: TextStyle(
                                    color: AppColors.app_green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // New Password Form
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New Password',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordField(
                        controller: _newPasswordController,
                        hintText: 'Enter new password',
                        obscureText: _obscureNewPassword,
                        onToggleObscure: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                        validator: _validateNewPassword,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      const Text(
                        'Confirm New Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        hintText: 'Confirm new password',
                        obscureText: _obscureConfirmPassword,
                        onToggleObscure: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        validator: _validateConfirmPassword,
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 30),
              
              // Action Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.app_green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _emailVerified ? _changePassword : _verifyEmail,
                  child: _isVerifying || _isChangingPassword
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _emailVerified ? 'Change Password' : 'Verify Email',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF6F7FB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[600],
          ),
          onPressed: onToggleObscure,
        ),
      ),
    );
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'New password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please confirm your new password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _onDigitChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      await EmailVerificationService.sendVerificationCode(widget.email);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent successfully!'),
            backgroundColor: AppColors.app_green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send verification code. Please try again.';
      });
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  Future<void> _verifyEmail() async {
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final verificationCode = _controllers.map((controller) => controller.text).join();
      
      if (verificationCode.length != 6) {
        setState(() {
          _errorMessage = 'Please enter the complete 6-digit verification code.';
        });
        return;
      }

      final isCodeValid = await EmailVerificationService.verifyCode(
        widget.email,
        verificationCode,
      );

      if (!isCodeValid) {
        setState(() {
          _errorMessage = 'Invalid verification code. Please try again.';
        });
        return;
      }

      // Email verified successfully, show password form
      setState(() {
        _emailVerified = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully! Now set your new password.'),
            backgroundColor: AppColors.app_green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text.trim().isEmpty || 
        _confirmPasswordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all password fields.';
      });
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }

    if (_newPasswordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters.';
      });
      return;
    }

    setState(() {
      _isChangingPassword = true;
      _errorMessage = null;
    });

    try {
      // Get the verification code that was used
      final verificationCode = _controllers.map((controller) => controller.text).join();
      
      // Use the new password recovery service
      final result = await PasswordRecoveryService.completePasswordRecovery(
        email: widget.email,
        verificationCode: verificationCode,
        newPassword: _newPasswordController.text.trim(),
      );

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: AppColors.app_green,
            ),
          );
          
          // Check if we used Firebase reset
          if (result['useFirebaseReset'] == true) {
            // Show additional message about checking email
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please check your email and click the reset link to complete the process.'),
                    backgroundColor: AppColors.app_green,
                    duration: Duration(seconds: 5),
                  ),
                );
              }
            });
          }
          
          // Navigate back based on context
          if (widget.isFromChangePassword) {
            Navigator.of(context).popUntil((route) => route.settings.name == '/user-information' || route.isFirst);
          } else {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to change password. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isChangingPassword = false;
      });
    }
  }
}
