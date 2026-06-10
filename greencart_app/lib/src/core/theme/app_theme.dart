import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF006A38);
  static const primaryContainer = Color(0xFF008648);
  static const surface = Color(0xFFF8FAF9);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF2F4F3);
  static const surfaceContainer = Color(0xFFECEEEE);
  static const succulentGreen = Color(0xFFE9F5EE);
  static const ripenedOrange = Color(0xFFFF9F1C);
  static const charcoalInk = Color(0xFF1A1C1B);
  static const mistGray = Color(0xFFE2E8E5);
  static const outline = Color(0xFF6E7A6F);
  static const outlineVariant = Color(0xFFBDCABD);
  static const deepForest = Color(0xFF1E4D34);

  static const radiusSm = 8.0;
  static const radiusMd = 16.0;
  static const radiusLg = 24.0;

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: charcoalInk.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get liftedShadow => [
    BoxShadow(
      color: charcoalInk.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  static BoxDecoration cardDecoration({
    Color color = surfaceContainerLowest,
    double radius = radiusMd,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: softShadow,
    );
  }

  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      secondary: ripenedOrange,
      onSecondary: charcoalInk,
      surface: surface,
      onSurface: charcoalInk,
      error: Color(0xFFBA1A1A),
      outline: outline,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: surface,
        foregroundColor: charcoalInk,
        titleTextStyle: TextStyle(
          color: charcoalInk,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: charcoalInk,
          height: 1.33,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: charcoalInk,
          height: 1.2,
        ),
        titleMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: charcoalInk,
          height: 1.4,
        ),
        titleSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: charcoalInk,
          height: 1.35,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: charcoalInk, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, color: outline, height: 1.45),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: primary,
          letterSpacing: 0.8,
          height: 1.3,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: succulentGreen,
        selectedColor: succulentGreen,
        disabledColor: surfaceContainer,
        labelStyle: const TextStyle(
          color: primary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: const TextStyle(
          color: primary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: primary, size: 18),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
        ),
        prefixIconColor: outline,
        suffixIconColor: outline,
        labelStyle: const TextStyle(
          color: outline,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(color: outline),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          foregroundColor: charcoalInk,
          side: const BorderSide(color: mistGray, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
