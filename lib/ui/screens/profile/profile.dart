import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_information.dart';
import 'user_vehicle.dart';
import 'voucher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth_gate.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  File? _selectedImage;
  Uint8List? _profilePhotoData;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto();
  }

  Future<void> _loadProfilePhoto() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists && doc.data()?['user_photo_data'] != null) {
        final blob = doc.data()?['user_photo_data'] as Blob;
        setState(() {
          _profilePhotoData = blob.bytes;
        });
      }
    } catch (e) {
      // Silently handle error - user might not have a photo yet
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        await _uploadImageToFirestore();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadImageToFirestore() async {
    if (_selectedImage == null) return;

    try {
      // Read the image file as bytes
      Uint8List imageBytes = await _selectedImage!.readAsBytes();

      // Check the size before uploading (1 MiB limit)
      if (imageBytes.lengthInBytes > 1048576) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image is too large! Maximum size is 1 MiB.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get current user
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Upload the bytes as a Blob to user's profile
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'user_photo_data': Blob(imageBytes), // Store bytes as a Blob
        'user_photo_updated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleSignOut() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog first
                try {
                  await FirebaseAuth.instance.signOut();
                  // Navigate to auth gate and clear the navigation stack
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const AuthGate(),
                      ),
                      (route) => false, // Remove all previous routes
                    );
                  }
                } catch (e) {
                  // Handle error if needed
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sign out failed: $e')),
                    );
                  }
                }
              },
              child: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Profile',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _HeaderBanner(
              selectedImage: _selectedImage,
              profilePhotoData: _profilePhotoData,
              onTap: _pickImage,
            ),
            const SizedBox(height: 30),
            _ActionCard(
              icon: Icons.person,
              title: 'My Profile',
              subtitle: 'Manage your personal details and contact info.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const UserInformationScreen(),
                  ),
                );
              },
            ),
            _ActionCard(
              icon: Icons.directions_car,
              title: 'My Vehicle',
              subtitle: 'View and edit your registered cars.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const UserVehicleScreen(),
                  ),
                );
              },
            ),
            _ActionCard(
              icon: Icons.percent,
              title: 'My Voucher',
              subtitle: 'View and claim your voucher.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const VoucherScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSignOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE44D4D),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Sign Out'),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF3F4F8),
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  final File? selectedImage;
  final Uint8List? profilePhotoData;
  final VoidCallback onTap;

  const _HeaderBanner({
    this.selectedImage,
    this.profilePhotoData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Top green banner
        Container(
          height: 130,
          decoration: BoxDecoration(
            color: const Color(0xFF29A87A),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        // Avatar overlapping the banner
        Positioned(
          left: 0,
          right: 0,
          bottom: -48,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selectedImage != null ? Colors.transparent : Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: selectedImage != null
                      ? ClipOval(
                          child: Image.file(
                            selectedImage!,
                            width: 104,
                            height: 104,
                            fit: BoxFit.cover,
                          ),
                        )
                      : profilePhotoData != null
                          ? ClipOval(
                              child: Image.memory(
                                profilePhotoData!,
                                width: 104,
                                height: 104,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.person, color: Colors.white, size: 56),
                ),
              ),
            ),
          ),
        ),
        // Spacer to accommodate avatar overlap
        const SizedBox(height: 80),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFD4EEE5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.black87, size: 28),
        ),
        title: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.black87),
        onTap: onTap,
      ),
    );
  }
}
