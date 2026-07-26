import 'package:flutter/material.dart';

/// EdSentre Modern Academic Brand Colors
/// 180-degree overhaul to professional Indigo & Teal card design.
class AppColors {
  // ═══════════════════════════════════════════════════════════════════════════
  // BRAND COLORS (Indigo & Teal)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color navy = Color(0xFF0F172A); // Slate-900 (Dark background)
  static const Color navyMid = Color(0xFF1E293B); // Slate-800 (Dark surface)
  static const Color navyLight = Color(0xFF334155); // Slate-700 (Dark border/outline)
  static const Color navyCard = navyMid; // Dark card surface

  static const Color teal = Color(0xFF0D9488); // Teal-600
  static const Color tealDeep = Color(0xFF0F766E); // Teal-700

  static const Color electric = Color(0xFF2563EB); // Royal Blue-600 (Primary Brand Accent)
  static const Color electricGlow = Color(0xFF60A5FA); // Blue-400

  static const Color white = Color(0xFFFFFFFF);
  static const Color whiteSoft = Color(0xFFF8FAFC); // Slate-50 (Light background)

  // ═══════════════════════════════════════════════════════════════════════════
  // GRAYS
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color gray100 = Color(0xFFE2E8F0); // Slate-200 (Light border)
  static const Color gray300 = Color(0xFFCBD5E1); // Slate-300
  static const Color gray500 = Color(0xFF64748B); // Slate-500
  static const Color gray700 = Color(0xFF475569); // Slate-600

  // ═══════════════════════════════════════════════════════════════════════════
  // STATUS & ALERTS
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color success = Color(0xFF10B981); // Emerald-500
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color danger = Color(0xFFEF4444); // Red-500
  static const Color gold = Color(0xFFF59E0B);
  static const Color statusSuccess = Color(0xFF10B981);
  static const Color statusInfo = Color(0xFF3B82F6);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color indigoLight = Color(0xFF818CF8);

  // ═══════════════════════════════════════════════════════════════════════════
  // BACKWARD COMPATIBILITY & ALIASES
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color primary = electric; // Now Royal Blue is primary
  static const Color primaryLight = electricGlow;
  static const Color primaryDark = navyMid;
  static const Color primarySoft = navyLight;
  static const Color secondary = teal;
  static const Color secondaryLight = teal;
  static const Color secondarySoft = navyLight;
  static const Color accent = teal;
  static const Color accentLight = tealDeep;
  static const Color accentSoft = navyLight;
  
  static const Color background = whiteSoft;
  static const Color surface = white;
  static const Color surfaceVariant = gray100;
  static const Color textPrimary = navy;
  static const Color textSecondary = gray700;
  static const Color textHint = gray500;
  static const Color textOnPrimary = white;

  static const Color error = danger;
  static const Color errorSoft = Color(0xFF7F1D1D);
  static const Color info = electric;
  static const Color infoSoft = navyLight;
  
  static const Color darkBackground = navy;
  static const Color darkSurface = navyMid;
  static const Color darkCard = navyMid;
  static const Color darkElevated = navyMid;
  static const Color darkBorder = navyLight;
  static const Color darkInput = navy;
  
  static const Color textOnDark = white;
  static const Color textOnDarkSecondary = gray300;
  static const Color textOnDarkHint = gray500;

  static const Color accentVivid = electric;
  static const Color accentMid = electricGlow;
  static const Color forestDeep = navy;
  static const Color forestPrimary = navyMid;
  static const Color alertCoral = danger;
  static const Color textBody = gray700;
  static const Color textDisplay = navy;
  static const Color textMuted = gray500;
  
  static const Color glassBorderHighlight = Color(0x11334155);
  static const Color glassFrost = Color(0x05334155);
  static const Color textDisabled = gray300;
  static const Color heroGlow = Color(0x1A2563EB);
  static const Color ambientGlow = Color(0x0A2563EB);
  static const Color warningAmber = warning;
  static const Color textMain = textPrimary;
  static const Color emeraldGreen = success;
  static const Color warmAmber = warning;
  static const Color infoPurple = teal;
  static const Color errorRed = danger;
  
  static Color glassWhite = Colors.white.withValues(alpha: 0.05);
  static Color glassBlack = Colors.black.withValues(alpha: 0.1);
  static Color glassBorder = gray100.withValues(alpha: 0.2);
  static Color glassHighlight = Colors.white.withValues(alpha: 0.02);
  
  static Color primaryGlow = electric.withValues(alpha: 0.1);
  static Color darkShadow = Colors.black.withValues(alpha: 0.05);
  static const Color shadow = Color(0x0A0F172A);

  static const Color divider = gray100;
  static const Color darkDivider = navyLight;

  static const Color present = success;
  static const Color absent = danger;
  static const Color late = warning;
  static const Color excused = electric;
  
  static const Color gray50 = whiteSoft;
  static const Color gray200 = gray100;
  static const Color gray400 = gray300;
  static const Color gray600 = gray500;
  static const Color gray800 = navyLight;
  static const Color gray900 = navy;

  // Gradients
  static const LinearGradient tealGradient = LinearGradient(
    colors: [tealDeep, teal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient tealToElectric = LinearGradient(
    colors: [electric, electricGlow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient primaryGradient = tealToElectric;
  static const LinearGradient primaryVerticalGradient = tealToElectric;
  static const LinearGradient secondaryGradient = tealGradient;
  static const LinearGradient accentGradient = tealGradient;
  static const LinearGradient glassWash = glassGradient;
  static const LinearGradient premiumSunset = LinearGradient(
    colors: [warning, danger],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient premiumOcean = tealToElectric;
  static const LinearGradient premiumRoyal = tealToElectric;
  static const LinearGradient premiumEmerald = tealGradient;
  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x08FFFFFF),
      Color(0x03FFFFFF),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient sunsetGradient = premiumSunset;
  static const LinearGradient oceanGradient = premiumOcean;
  static const LinearGradient successGradient = premiumEmerald;
  static const LinearGradient cardGradient = LinearGradient(
    colors: [white, whiteSoft],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const List<BoxShadow> glassShadow = softGlow;
  static const List<BoxShadow> neonGlow = softGlow;
  static const List<BoxShadow> softGlow = [
    BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 10,
      spreadRadius: 0,
      offset: Offset(0, 4),
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // ROLE-BASED PSYCHOLOGICAL PALETTES (Teacher vs Parent)
  // ═══════════════════════════════════════════════════════════════════════════
  // Teacher (Power Operator: Efficiency, High Contrast, Focus)
  static const Color teacherPrimary = electric; // Royal Indigo #2563EB
  static const Color teacherAccent = teal; // Electric Teal #0D9488
  static const LinearGradient teacherGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Parent (Encouraging Guardian: Reassurance, Calm, Clarity)
  static const Color parentPrimary = success; // Emerald Mint #10B981
  static const Color parentAccent = Color(0xFF0284C7); // Serene Sky Blue #0284C7
  static const Color parentWarm = warning; // Soft Amber #F59E0B
  static const LinearGradient parentGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// ═════════════════════════════════════════════════════════════════════════════
/// DYNAMIC THEME COLOR EXTENSIONS (Zero Dark/Light Mode Collision)
/// Implements automatic contrast switching without hardcoded values.
/// ═════════════════════════════════════════════════════════════════════════════
extension AppColorsContextExtension on BuildContext {
  /// True if current ThemeMode is Dark Mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // ── Universal Adaptive Surfaces & Backgrounds ──────────────────────────
  Color get themeBackground => isDarkMode ? AppColors.navy : AppColors.whiteSoft;
  Color get themeSurface => isDarkMode ? AppColors.navyMid : AppColors.white;
  Color get themeCard => isDarkMode ? AppColors.navyMid : AppColors.white;
  Color get themeBorder => isDarkMode ? AppColors.navyLight : AppColors.gray100;
  Color get themeDivider => isDarkMode ? AppColors.navyLight : AppColors.gray100;

  // ── Universal Adaptive Text Colors ──────────────────────────────────────
  Color get themeTextPrimary => isDarkMode ? AppColors.white : AppColors.navy;
  Color get themeTextSecondary => isDarkMode ? AppColors.gray300 : AppColors.gray700;
  Color get themeTextHint => isDarkMode ? AppColors.gray500 : AppColors.gray500;

  // ── Adaptive Shadows & Highlights ───────────────────────────────────────
  List<BoxShadow> get themeShadow => isDarkMode 
      ? [const BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4))]
      : [const BoxShadow(color: Color(0x0A0F172A), blurRadius: 10, offset: Offset(0, 4))];

  // ── Role-Specific Adaptive Primary Color ────────────────────────────────
  Color rolePrimary({required bool isParent}) => isParent ? AppColors.parentPrimary : AppColors.teacherPrimary;
  LinearGradient roleGradient({required bool isParent}) => isParent ? AppColors.parentGradient : AppColors.teacherGradient;
  Color get teacherAccent => AppColors.teacherAccent;
  Color get themeError => AppColors.danger;
}

