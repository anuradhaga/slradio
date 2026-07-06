import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors
  static const Color background = Color(0xFF0A0D14);
  static const Color surface = Color(0xFF161B26);
  static const Color accent = Color(0xFF8A2387);
  static const Color accentGlow = Color(0xFFE94057);
  
  static const Color textPrimary = Color(0xFFF5F6F9);
  static const Color textSecondary = Color(0xFF8F9CAE);
  static const Color textMuted = Color(0xFF5A6675);

  // Glassmorphic border & colors
  static final Color glassBg = Colors.white.withOpacity(0.06);
  static final Color glassBorder = Colors.white.withOpacity(0.08);
  static final Color glassShadow = Colors.black.withOpacity(0.3);

  static BoxDecoration glassDecoration({
    BorderRadius? borderRadius,
    Color? customColor,
    Color? customBorderColor,
  }) {
    return BoxDecoration(
      color: customColor ?? glassBg,
      borderRadius: borderRadius ?? BorderRadius.circular(24),
      border: Border.all(
        color: customBorderColor ?? glassBorder,
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: glassShadow,
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // Get ThemeData for the application
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentGlow,
        background: background,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: textPrimary,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          displayMedium: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          titleLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          titleMedium: const TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
          bodyLarge: const TextStyle(color: textPrimary),
          bodyMedium: const TextStyle(color: textSecondary),
          bodySmall: const TextStyle(color: textMuted),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: Colors.white,
        inactiveTrackColor: Colors.white.withOpacity(0.2),
        thumbColor: Colors.white,
        overlayColor: Colors.white.withOpacity(0.1),
        trackHeight: 4,
      ),
    );
  }
}
