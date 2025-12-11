import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/email_verification_service.dart';

class SimpleForgotPasswordScreen extends StatefulWidget {
  final String email;
  final bool isFromChangePassword;

  const SimpleForgotPasswordScreen({
    super.key,
    required this.email,
    this.isFromChangePassword = false,
  });

  @override
  State<SimpleForgotPasswordScreen> createState() => _SimpleForgotPasswordScreenState();
}

class _SimpleForgotPasswordScreenState extends State<SimpleForgotPasswordScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  
  bool _isResending = false;
  bool _isVerifying = false;
  bool _isSendingReset = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
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
        title: const Text(
          'Reset Password',
          style: TextStyle(color: Colors.black),
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
                    const Text(
                      'Verify Your Email',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We sent a 6-digit verification code to:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.email,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.app_green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enter the code below to verify your email, then we\'ll send you a password reset link.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
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
              
              const SizedBox(height: 30),
              
              // Verify Button
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
                  onPressed: _isVerifying || _isSendingReset ? null : _verifyAndSendReset,
                  child: _isVerifying || _isSendingReset
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verify Email & Send Reset Link',
                          style: TextStyle(
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

  Future<void> _verifyAndSendReset() async {
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      // Get the verification code from the input fields
      final verificationCode = _controllers.map((controller) => controller.text).join();
      
      if (verificationCode.length != 6) {
        setState(() {
          _errorMessage = 'Please enter the complete 6-digit verification code.';
        });
        return;
      }

      // Step 1: Verify the 6-digit code using your email verification service
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

      // Step 2: After email verification, send Firebase password reset email
      setState(() {
        _isVerifying = false;
        _isSendingReset = true;
      });

      await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verification successful! Please check your email for the password reset link from Firebase.'),
            backgroundColor: AppColors.app_green,
          ),
        );
        
        // Navigate back based on context
        if (widget.isFromChangePassword) {
          Navigator.of(context).popUntil((route) => route.settings.name == '/user-information' || route.isFirst);
        } else {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isVerifying = false;
        _isSendingReset = false;
      });
    }
  }
}
