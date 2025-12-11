import 'package:flutter/material.dart';
import 'app_colors.dart';

final ThemeData appTheme = ThemeData(
  primaryColor: AppColors.app_green,
  scaffoldBackgroundColor: AppColors.background,
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.app_green,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(fontSize: 16),
    bodyMedium: TextStyle(fontSize: 14),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.app_green,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
);
