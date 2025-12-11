import 'package:assignment/services/notification_service.dart';
import 'package:assignment/ui/screens/reminder/notification.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'auth_gate.dart';
import 'core/constants/theme.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init(navigatorKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Greenstem',
      theme: appTheme,
      navigatorKey: navigatorKey,
      routes: {
        "/notificationPage": (context) => const NotificationPage(),
      },
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );


  }
}