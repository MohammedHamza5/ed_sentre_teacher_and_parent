import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// EdSentre Radical Glassmorphism 2.0 Theme Configuration
/// Forest Dark First Design
class AppTheme {
  // We use Syne for Display/Headings, and DM Sans for Body.
  // We use Cairo for Arabic specifically to maintain legibility while being modern.

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK THEME (FOREST DARK - PRIMARY)
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.accentVivid,
      scaffoldBackgroundColor: AppColors.forestDeep,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentVivid,
        primaryContainer: AppColors.accentMid,
        secondary: AppColors.warmAmber,
        secondaryContainer: AppColors.emeraldGreen,
        tertiary: AppColors.infoPurple,
        surface: AppColors.darkSurface,
        error: AppColors.alertCoral,
        onPrimary: AppColors.forestDeep,
        onSecondary: AppColors.forestDeep,
        onSurface: AppColors.textDisplay,
        onError: Colors.white,
        outline: AppColors.darkBorder,
        shadow: Colors.black,
      ),

      // AppBar Theme (No Background, Glassmorphism handles it)
      appBarTheme: const AppBarTheme(
        color: Colors.transparent,
        foregroundColor: AppColors.textDisplay,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: GoogleFonts.syne(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textDisplay,
        ),
        displayMedium: GoogleFonts.syne(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textDisplay,
        ),
        displaySmall: GoogleFonts.syne(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textDisplay,
        ),
        headlineLarge: GoogleFonts.syne(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textDisplay,
        ),
        headlineMedium: GoogleFonts.syne(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textDisplay,
        ),
        headlineSmall: GoogleFonts.syne(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textDisplay,
        ),
        titleLarge: GoogleFonts.syne(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textDisplay,
        ),
        titleMedium: GoogleFonts.syne(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textDisplay,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textBody,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textBody,
        ),
        bodySmall: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.textMuted,
        ),
        labelLarge: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textDisplay,
        ),
        labelSmall: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
      ),

      // Card Theme (We will barely use this in favor of GlassCard, but good to have)
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.glassBorderHighlight),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.forestPrimary.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.accentVivid, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.alertCoral),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.alertCoral, width: 2),
        ),
        hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14),
        labelStyle: GoogleFonts.dmSans(
          color: AppColors.textBody,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        dragHandleColor: AppColors.textMuted.withValues(alpha: 0.5),
        dragHandleSize: const Size(48, 6),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: BorderSide(color: AppColors.glassBorderHighlight),
        ),
        titleTextStyle: GoogleFonts.syne(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textDisplay,
        ),
        contentTextStyle: GoogleFonts.dmSans(
          fontSize: 14,
          color: AppColors.textBody,
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textBody, size: 24),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME (STUB FOR NOW - WE FOCUS ON DARK)
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.accentMid,
      scaffoldBackgroundColor: AppColors.background,

      // Basic assignment, same fonts
      textTheme: TextTheme(
        displayLarge: GoogleFonts.syne(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        headlineLarge: GoogleFonts.syne(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16,
          color: AppColors.textSecondary,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
