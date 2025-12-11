import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import 'login.dart';
import 'email_verification_screen.dart';
import '../../../models/user_model.dart';
import '../../../services/email_verification_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone is required';
    }
    final phoneRegex = RegExp(
      r'^(?:'
      r'0?11[- ]?\d{8}'              // 011 with or without 0, 8 digits
      r'|0?1[0,2-9][- ]?\d{7,8}'     // 010, 012–019 with or without 0, 7–8 digits
      r'|0?[3-9][- ]?\d{6,8}'        // Landline 03–09 with or without 0, 6–8 digits
      r'|\d{8}'                      // Raw 8-digit number
      r')$'
    );
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid Malaysian phone number';
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // void _handleSignUp() {
  //   if (_formKey.currentState!.validate()) {
  //     if (!_agreeToTerms) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Please agree to the terms and conditions'),
  //           backgroundColor: AppColors.error,
  //         ),
  //       );
  //       return;
  //     }
  //     // Handle sign up logic here
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Account created successfully!'),
  //         backgroundColor: AppColors.app_green,
  //       ),
  //     );
  //   }
  // }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please agree to the terms and conditions'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Always require email verification for new signups
      // Clear any old verification records first
      await EmailVerificationService.clearVerificationRecords(_emailController.text.trim());
      
      // Send verification code first
      final emailSent = await EmailVerificationService.sendVerificationCode(
        _emailController.text.trim(),
        userName: _nameController.text.trim(),
      );
      
      if (!emailSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send verification email. Please check your email address and try again.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Show success message that email was sent
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code sent to your email!'),
          backgroundColor: AppColors.app_green,
        ),
      );
      
      // Navigate to email verification screen
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => EmailVerificationScreen(
            email: _emailController.text.trim(),
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text.trim(),
          ),
        ),
      );

      // If verification was successful, proceed with account creation
      if (result == true) {
        await _createUserAccount();
      }
    }
  }

  Future<void> _createUserAccount() async {
    try {
      final tempPassword = _passwordController.text.trim();
      final tempEmail = _emailController.text.trim();
      final tempName = _nameController.text.trim();
      final tempPhone = _phoneController.text.trim();
      
      // Create Firebase Auth user
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: tempEmail,
        password: tempPassword,
      );

      // Update display name
      await FirebaseAuth.instance.currentUser?.updateDisplayName(tempName);

      // Get the UID from Firebase Auth
      final uid = FirebaseAuth.instance.currentUser!.uid;
      
      // Create user model for Firestore (without password - Firebase Auth handles passwords)
      final userModel = UserModel(
        userId: uid,
        userName: tempName,
        password: '', // Empty - Firebase Auth handles password management
        email: tempEmail,
        phoneNo: tempPhone,
        address: '', // no address field in signup; set empty for now
        userPhoto: null,
        point: 0,
      );
      
      // Save to users collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userModel.toJson(), SetOptions(merge: true));

      // Clean up verification record
      await EmailVerificationService.deleteVerificationRecord(tempEmail);

      // Sign out the user to force them to login again
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please log in.'),
            backgroundColor: AppColors.app_green,
          ),
        );

        // Navigate back to login screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Clean up temp data on error
      try {
        await FirebaseFirestore.instance
            .collection('temp_signup')
            .doc(_emailController.text.trim())
            .delete();
      } catch (_) {}
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign up failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }






  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Logo
                Center(
                  child: Image.asset(
                    'assets/images/company/company_placeholder.png',
                    height: 100,
                    width: 100,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 30),
                // Welcome Text
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please fill in the information below',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                // Name Field
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
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter your full name',
                      prefixIcon: Icon(Icons.person_outlined, color: AppColors.app_green),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 15),
                // Email Field
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
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.app_green),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 15),
                // Phone Field
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
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter your phone number',
                      prefixIcon: Icon(Icons.phone_outlined, color: AppColors.app_green),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: _validatePhone,
                  ),
                ),
                const SizedBox(height: 15),
                // Password Field
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
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.app_green),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
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
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 15),
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
                      labelText: 'Confirm Password',
                      hintText: 'Confirm your password',
                      prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.app_green),
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
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Terms and Conditions
                Row(
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                        });
                      },
                      activeColor: AppColors.app_green,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _agreeToTerms = !_agreeToTerms;
                          });
                        },
                        child: const Text(
                          'I agree to the Terms and Conditions',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Sign Up Button
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
                    onPressed: _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.app_green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: _navigateToLogin,
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: AppColors.app_green,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
