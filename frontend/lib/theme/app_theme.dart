import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
// All values from the mobile-design-handoff.md spec.

class AppColors {
  // Light
  static const ink        = Color(0xFF1B2420); // main text on light
  static const muted      = Color(0xFF55605A); // secondary text on light
  static const bg         = Color(0xFFF4F6F3); // screen background (sage tint)
  static const card       = Color(0xFFFFFFFF); // cards, inputs, bars
  static const line       = Color(0xFFD9DFD9); // 1 px borders on light
  static const green      = Color(0xFF2F5D46); // ratings, active tab, outline btns, user bubble
  static const accent     = Color(0xFFC5DC5A); // primary buttons, mic, highlights
  static const accentEdge = Color(0xFF8DA52E); // 1 px inset on accent buttons

  // Dark (cooking mode)
  static const darkBg      = Color(0xFF16201B); // cooking screen background
  static const darkSurface = Color(0xFF22302A); // cards on dark
  static const darkLine    = Color(0xFF3A4A41); // borders on dark
  static const darkMuted   = Color(0xFFA9B5AE); // secondary text on dark
  static const darkText    = Color(0xFFF4F6F3); // main text on dark
  static const progressTrack = Color(0xFF2A3A32); // progress bar track on dark

  // Semantic
  static const error   = Color(0xFFDC2626);
  static const success = Color(0xFF16A34A);
}

class AppTypography {
  // Heading / recipe title / big numbers
  static TextStyle display(double size, {Color? color, double? height}) =>
      GoogleFonts.bricolageGrotesque(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.ink,
        height: height,
        letterSpacing: size >= 24 ? -0.5 : 0,
      );

  static TextStyle heading(double size, {Color? color}) =>
      GoogleFonts.bricolageGrotesque(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.ink,
        letterSpacing: size >= 20 ? -0.3 : 0,
      );

  // Body
  static TextStyle body(double size, {FontWeight? weight, Color? color, double? height}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        color: color ?? AppColors.ink,
        height: height,
      );

  // Small caps label: 13 px, uppercase, letter-spacing 0.06em
  static TextStyle smallCaps({Color? color}) => GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: color ?? AppColors.muted,
    letterSpacing: 0.78, // 0.06em ≈ 13 * 0.06
  );
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.green,
        secondary: AppColors.accent,
        surface: AppColors.card,
        onSurface: AppColors.ink,
        outline: AppColors.line,
      ),
      textTheme: _textTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.display(20),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.line),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTypography.body(15, color: AppColors.muted),
      ),
      // Accent-filled primary button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.ink,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: AppColors.accentEdge),
          ),
          textStyle: AppTypography.body(16, weight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.green,
          side: const BorderSide(color: AppColors.green),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: AppTypography.body(15, weight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.green,
          textStyle: AppTypography.body(15, weight: FontWeight.w500),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.card,
        labelStyle: AppTypography.body(13, weight: FontWeight.w500, color: AppColors.muted),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.green,
        unselectedItemColor: AppColors.muted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppTypography.body(15, weight: FontWeight.w700),
        unselectedLabelStyle: AppTypography.body(15, weight: FontWeight.w500),
      ),
    );
  }

  static TextTheme _textTheme() => TextTheme(
    displayLarge:  AppTypography.display(30),
    displayMedium: AppTypography.display(26),
    displaySmall:  AppTypography.display(22),
    headlineLarge:  AppTypography.heading(24),
    headlineMedium: AppTypography.heading(20),
    headlineSmall:  AppTypography.heading(18),
    titleLarge:  AppTypography.body(17, weight: FontWeight.w600),
    titleMedium: AppTypography.body(15, weight: FontWeight.w600),
    titleSmall:  AppTypography.body(13, weight: FontWeight.w600),
    bodyLarge:   AppTypography.body(16, height: 1.6),
    bodyMedium:  AppTypography.body(14, height: 1.5),
    bodySmall:   AppTypography.body(12, color: AppColors.muted),
    labelLarge:  AppTypography.body(14, weight: FontWeight.w500),
    labelMedium: AppTypography.body(12, weight: FontWeight.w500, color: AppColors.muted),
    labelSmall:  AppTypography.body(11, weight: FontWeight.w500, color: AppColors.muted),
  );
}
