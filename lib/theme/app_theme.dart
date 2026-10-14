import 'package:flutter/material.dart';

class AppColors {
  static const forest = Color(0xFF0B4F3A);
  static const accent = Color(0xFF1FA06E);
  static const mint = Color(0xFFE6F5EE);
  static const mintLight = Color(0xFFF4FBF8);
  static const field = Color(0xFFF6F8F7);
  static const border = Color(0xFFE3E8E5);
  static const ink = Color(0xFF14201B);
  static const muted = Color(0xFF6B7772);
}

class AppTheme {
  static OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c, width: w),
      );

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.forest,
        primary: AppColors.forest,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.mintLight,
    );
    return base.copyWith(
        textTheme: base.textTheme
      .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.field,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        hintStyle: const TextStyle(color: Color(0xFF8C9791), fontSize: 15),
        border: _border(AppColors.border),
        enabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.forest, 1.5),
        errorBorder: _border(const Color(0xFFD9534F)),
        focusedErrorBorder: _border(const Color(0xFFD9534F), 1.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.forest,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.mint,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: s.contains(WidgetState.selected) ? AppColors.forest : AppColors.muted,
            )),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected) ? AppColors.forest : AppColors.muted,
            )),
      ),
    );
  }
}
