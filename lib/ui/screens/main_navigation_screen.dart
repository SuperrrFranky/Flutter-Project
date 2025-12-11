import 'package:flutter/material.dart';
import '../widgets/bottom_navbar.dart';
import 'dashboard/dashboard_screen.dart';
import 'booking/booking.dart';
import 'payment/billing.dart';
import 'profile/profile.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final GlobalKey<DashboardScreenState> _dashboardKey = GlobalKey<DashboardScreenState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardScreen(key: _dashboardKey),
      const Booking(),
      const Billing(),
      const Profile(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Refresh dashboard when switching back to it
    if (index == 0 && _dashboardKey.currentState != null) {
      _dashboardKey.currentState!.loadUserName();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
