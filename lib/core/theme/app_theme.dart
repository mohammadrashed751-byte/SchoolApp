import 'package:flutter/material.dart';

import '../utils/responsive.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light(BuildContext context) {
    final inputRadius = BorderRadius.circular(responsiveWidth(context, 14));
    final buttonRadius = BorderRadius.circular(responsiveWidth(context, 14));

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.pageBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: responsiveWidth(context, 21),
        ),
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          // Disabled/incomplete state reads as plain gray-on-gray, matching
          // the reference design, instead of a faded tint of the brand color.
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textHint,
          minimumSize: Size(double.infinity, responsiveHeight(context, 58)),
          textStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: responsiveWidth(context, 17),
          ),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldFill,
        contentPadding: EdgeInsets.symmetric(
          horizontal: responsiveWidth(context, 18),
          vertical: responsiveHeight(context, 22),
        ),
        border: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        iconColor: AppColors.textHint,
        prefixIconColor: AppColors.textHint,
        hintStyle: TextStyle(
          color: AppColors.textHint,
          fontSize: responsiveWidth(context, 15),
        ),
        labelStyle: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: responsiveWidth(context, 15),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontSize: responsiveWidth(context, 31),
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontSize: responsiveWidth(context, 26),
        ),
        headlineSmall: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontSize: responsiveWidth(context, 22),
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontSize: responsiveWidth(context, 19),
        ),
        bodyLarge: TextStyle(
          color: AppColors.textSecondary,
          fontSize: responsiveWidth(context, 17),
          height: 1.35,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: responsiveWidth(context, 15),
        ),
      ),
    );
  }
}
