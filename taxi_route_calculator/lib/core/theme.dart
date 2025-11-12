// iOS Cupertino тема для приложения
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'constants.dart';

/// iOS Cupertino тема приложения
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: '.SF Pro Display',
      scaffoldBackgroundColor: AppColors.white,
      
      colorScheme: const ColorScheme.light(
        primary: AppColors.black,
        secondary: AppColors.gray,
        surface: AppColors.white,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.black,
      ),
      
      // iOS стиль текста
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 34.0,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
          letterSpacing: 0.0,
        ),
        displayMedium: TextStyle(
          fontSize: 28.0,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
          letterSpacing: 0.0,
        ),
        titleLarge: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
          letterSpacing: 0.38,
        ),
        titleMedium: TextStyle(
          fontSize: 17.0,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
          letterSpacing: -0.41,
        ),
        bodyLarge: TextStyle(
          fontSize: 17.0,
          fontWeight: FontWeight.w400,
          color: AppColors.black,
          letterSpacing: -0.41,
        ),
        bodyMedium: TextStyle(
          fontSize: 15.0,
          fontWeight: FontWeight.w400,
          color: AppColors.black,
          letterSpacing: -0.24,
        ),
        labelLarge: TextStyle(
          fontSize: 13.0,
          fontWeight: FontWeight.w400,
          color: AppColors.gray,
          letterSpacing: -0.08,
        ),
      ),
      
      // Тени в стиле iOS
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        color: AppColors.white,
        shadowColor: AppColors.black.withValues(alpha: 0.1),
      ),
      
      // Кнопки в стиле iOS
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.medium,
            vertical: AppPadding.small,
          ),
        ),
      ),
    );
  }
  
  /// Cupertino тема
  static CupertinoThemeData get cupertinoTheme {
    return const CupertinoThemeData(
      primaryColor: AppColors.black,
      scaffoldBackgroundColor: AppColors.white,
      barBackgroundColor: AppColors.white,
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.black,
        textStyle: TextStyle(
          fontFamily: '.SF Pro Display',
          fontSize: 17.0,
          color: AppColors.black,
          letterSpacing: -0.41,
        ),
      ),
    );
  }
}
