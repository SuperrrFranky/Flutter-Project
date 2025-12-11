import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth_gate.dart';
import '../../widgets/bottom_navbar.dart';
import '../feedback/feedback.dart';
import '../reminder/notification.dart';
import '../services/car_services_screen.dart';
import '../progress/progress_service.dart';
import '../profile/profile.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FD),
      body: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: 12),
          _buildSection(
            context,
            items: const [
              _MenuItemData(icon: Icons.person_outline, label: 'My Account'),
              _MenuItemData(icon: Icons.notifications_none, label: 'Notification'),
            ],
          ),
          const SizedBox(height: 12),
          _buildSection(
            context,
            items: const [
              _MenuItemData(icon: Icons.car_repair, label: 'Car Services'),
              _MenuItemData(icon: Icons.car_repair, label: 'Progress'),
            ],
          ),
          const SizedBox(height: 12),
          _buildSection(
            context,
            items: const [
              _MenuItemData(icon: Icons.share_outlined, label: 'Share'),
              _MenuItemData(icon: Icons.feedback_outlined, label: 'Feedback'),
            ],
          ),
          const SizedBox(height: 12),
          _buildSection(
            context,
            items: const [
              _MenuItemData(icon: Icons.logout, label: 'Logout'),
            ],
          ),
          const Spacer(),
          BottomNavbar(
            currentIndex: 0, // Home is active since we're navigating from dashboard
            onTap: (index) {
              // Handle navigation back to main navigation
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 100 + MediaQuery.of(context).padding.top,
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 25, left: 16, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF282828)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Center(
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Color(0xFF282828),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          // Keep space for right-aligned action parity (none in design)
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {String? header, IconData? headerIcon, required List<_MenuItemData> items}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 20, bottom: 6),
              child: Row(
                children: [
                  if (headerIcon != null) ...[
                    Icon(headerIcon, color: Colors.black.withOpacity(0.3), size: 24),
                    const SizedBox(width: 25),
                  ],
                  Text(
                    header,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ...items.map((e) => _MenuTile(data: e)),
        ],
      ),
    );
  }

}

class _MenuTile extends StatelessWidget {
  final _MenuItemData data;
  const _MenuTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (data.label == 'My Account') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const Profile()),
          );
        } else if (data.label == 'Car Services') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CarServicesScreen()),
          );
        }else if (data.label == 'Progress') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProgressServiceListScreen()),
          );
        }else if (data.label == 'Feedback') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FeedbackPage()),
          );
        }else if (data.label == 'Notification') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => NotificationPage()),
          );
        }else if (data.label == 'Logout') {
          try {
            await FirebaseAuth.instance.signOut();
          } catch (e) {
            // even if signOut throws, proceed to AuthGate to recover via stream
          }
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AuthGate()),
              (route) => false,
            );
          }
        }
        // Add other navigation cases here as needed
      },
      child: Container(
        height: 60,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(data.icon, color: Colors.black.withOpacity(0.3)),
            const SizedBox(width: 25),
            Text(
              data.label,
              style: const TextStyle(fontSize: 15, color: Colors.black),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String label;
  const _MenuItemData({required this.icon, required this.label});
}



