import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/user_model.dart';
import 'change_password_screen.dart';

class UserInformationScreen extends StatefulWidget {
  const UserInformationScreen({super.key});

  @override
  State<UserInformationScreen> createState() => _UserInformationScreenState();
}

class _UserInformationScreenState extends State<UserInformationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _loading = true;
  String? _currentUserId;
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'User Information',
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              )),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('User Name'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _userNameController,
                      hintText: 'Enter user name',
                      keyboardType: TextInputType.name,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'User name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Email'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _emailController,
                      hintText: 'Enter email',
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Phone No'),
                    const SizedBox(height: 8),
                    _buildPhoneField(),
                    const SizedBox(height: 16),
                    _buildLabel('Address'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _addressController,
                      hintText: 'Enter address',
                      keyboardType: TextInputType.streetAddress,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    _ChangePasswordTile(
                      onTap: () {
                        print('Change password button tapped');
                        print('Current User ID: $_currentUserId');
                        print('Current User Email: $_currentUserEmail');
                        
                        if (_currentUserId != null && _currentUserEmail != null) {
                          print('Navigating to change password screen');
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ChangePasswordScreen(
                                userEmail: _currentUserEmail!,
                                userId: _currentUserId!,
                              ),
                            ),
                          );
                        } else {
                          print('User session not found');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User session not found. Please log in again.')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    final isValid = _formKey.currentState?.validate() ?? false;
                    if (!isValid) return;
                    try {
                      final uid = FirebaseAuth.instance.currentUser!.uid;
                      final model = UserModel(
                        userId: uid,
                        userName: _userNameController.text.trim(),
                        email: _emailController.text.trim(),
                        phoneNo: _phoneController.text.trim(),
                        address: _addressController.text.trim(),
                        userPhoto: null,
                      );
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .set(model.toJson(), SetOptions(merge: true));
                      
                      // Also update FirebaseAuth displayName for consistency
                      await FirebaseAuth.instance.currentUser?.updateDisplayName(_userNameController.text.trim());
                      
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Saved successfully')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Save failed: $e')),
                      );
                    }
                  },
                  child: const Text('Save / Update'),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _loadUser() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() => _loading = false);
        return;
      }
      
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null) {
        _userNameController.text = (data['user_name'] ?? '').toString();
        _emailController.text = (data['email'] ?? '').toString();
        _phoneController.text = (data['phoneNo'] ?? '').toString();
        _addressController.text = (data['address'] ?? '').toString();
        
        // Store user info for password change
        _currentUserId = uid;
        _currentUserEmail = data['email'] ?? '';
      }
    } catch (_) {
      // ignore, keep fields as-is
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black87,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: const Text(
              '+60',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: const Color(0xFFE5E7EB),
          ),
          Expanded(
            child: TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: _validatePhone,
              decoration: const InputDecoration(
                hintText: 'e.g. 012-3456789 or 12345678',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
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
      ),
    );
  }
}

class _ChangePasswordTile extends StatelessWidget {
  final VoidCallback onTap;
  const _ChangePasswordTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: const Text(
          'Change Password',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}

