import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class BottomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.08,
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          backgroundColor: AppColors.white,
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedItemColor: AppColors.app_green,
          unselectedItemColor: AppColors.app_grey,
          items: [
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/icons/home_icon.png',
                width: 22,
                height: 22,
                color: currentIndex == 0
                    ? AppColors.app_green
                    : AppColors.app_grey,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/icons/services_icon.png',
                width: 22,
                height: 22,
                color: currentIndex == 1
                    ? AppColors.app_green
                    : AppColors.app_grey,
              ),
              label: 'Services',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  Image.asset(
                    'assets/icons/payment_icon.png',
                    width: 22,
                    height: 22,
                    color: currentIndex == 2
                        ? AppColors.app_green
                        : AppColors.app_grey,
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE54545),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              label: 'Payment',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/icons/profile_icon.png',
                width: 22,
                height: 22,
                color: currentIndex == 3
                    ? AppColors.app_green
                    : AppColors.app_grey,
              ),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
