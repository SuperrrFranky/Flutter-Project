import 'package:assignment/services/notification_listener.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ui/screens/main_navigation_screen.dart';
import 'ui/screens/profile/login.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          FirestoreNotificationListener.startListening(user.uid);
          return const MainNavigationScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
