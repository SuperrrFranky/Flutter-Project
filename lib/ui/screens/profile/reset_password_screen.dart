import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/email_verification_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final bool isFromChangePassword;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    this.isFromChangePassword = false,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isResending = false;
  bool _isVerifying = false;
  bool _isResetting = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  int _resendCountdown = 0;
  String? _errorMessage;
  bool _isCodeVerified = false;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }


  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60; // 60 seconds countdown
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCountdown--;
        });
        return _resendCountdown > 0;
      }
      return false;
    });
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    final success = await EmailVerificationService.sendVerificationCode(widget.email);
    
    if (mounted) {
      setState(() {
        _isResending = false;
      });

      if (success) {
        _startResendCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent to your email!'),
            backgroundColor: AppColors.app_green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to resend verification code. Please try again.';
        });
      }
    }
  }

  Future<void> _verifyCode() async {
    final code = _controllers.map((controller) => controller.text).join();
    
    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit code';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final isValid = await EmailVerificationService.verifyCode(widget.email, code);
    
    if (mounted) {
      setState(() {
        _isVerifying = false;
      });

      if (isValid) {
        setState(() {
          _isCodeVerified = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code verified! Now enter your new password.'),
            backgroundColor: AppColors.app_green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Invalid verification code. Please try again.';
        });
        // Clear all fields
        for (final controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    }
  }


  Future<void> _resetPassword() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isResetting = true;
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

      // Step 2: Since we can't retrieve the original password from Firebase Auth,
      // we'll use Firebase's built-in password reset email
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
          // If coming from change password, go back to user information
          Navigator.of(context).popUntil((route) => route.settings.name == '/user-information' || route.isFirst);
        } else {
          // If coming from login, go back to login
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isResetting = false;
      });
    }
  }

  void _onDigitChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyCode();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.app_green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isCodeVerified ? Icons.lock_open : Icons.lock_reset,
                  size: 40,
                  color: AppColors.app_green,
                ),
              ),
              const SizedBox(height: 30),
              // Title
              Text(
                _isCodeVerified ? 'Set New Password' : 'Verify Your Email',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              // Description
              Text(
                _isCodeVerified 
                    ? 'Enter your new password below'
                    : 'We\'ve sent a 6-digit verification code to\n${widget.email}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              if (!_isCodeVerified) ...[
                // Code input fields
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
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _errorMessage != null ? Colors.red : Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _errorMessage != null ? Colors.red : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.app_green,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        onChanged: (value) => _onDigitChanged(value, index),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                // Verify button
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.app_green.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.app_green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Verify Code',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                // Resend code
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Didn\'t receive the code? ',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: _resendCountdown > 0 ? null : _resendCode,
                      child: Text(
                        _resendCountdown > 0
                            ? 'Resend in ${_resendCountdown}s'
                            : 'Resend Code',
                        style: TextStyle(
                          color: _resendCountdown > 0 ? Colors.grey : AppColors.app_green,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isResending)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.app_green,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
              ] else ...[
                // Password Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // New Password Field
                      Container(
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
                        child: TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscureNewPassword,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            hintText: 'Enter your new password',
                            prefixIcon: const Icon(
                              Icons.lock_outlined,
                              color: AppColors.app_green,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureNewPassword = !_obscureNewPassword;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your new password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Confirm Password Field
                      Container(
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
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirm New Password',
                            hintText: 'Confirm your new password',
                            prefixIcon: const Icon(
                              Icons.lock_outlined,
                              color: AppColors.app_green,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your new password';
                            }
                            if (value != _newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Reset Password Button
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.app_green.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isResetting ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.app_green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isResetting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Reset Password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
