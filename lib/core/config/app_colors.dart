import 'package:flutter/material.dart';

/// EdSentre Premium Color Palette
/// Dark Mode First - Professional Colors for Teachers & Parents
///
/// 🎨 Design Philosophy:
/// - Deep, calming backgrounds for long reading sessions
/// - Professional yet warm accent colors
/// - High contrast for accessibility
/// - Subtle gradients for premium feel
class AppColors {
  // ═══════════════════════════════════════════════════════════════════════════
  // DARK MODE FOUNDATION (Primary Theme)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Deep Space - Main Background
  static const Color darkBackground = Color(0xFF0A0A0F);

  /// Elevated Surface - Cards & Containers
  static const Color darkSurface = Color(0xFF12121A);

  /// Card Background - Slightly elevated
  static const Color darkCard = Color(0xFF1A1A25);

  /// Elevated Elements - Modals, Drawers
  static const Color darkElevated = Color(0xFF222230);

  /// Subtle Border
  static const Color darkBorder = Color(0xFF2A2A3A);

  /// Input Field Background
  static const Color darkInput = Color(0xFF16161F);

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIMARY COLORS - Teacher Blue (Professional & Trustworthy)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Primary Blue - Authority & Trust
  static const Color primary = Color(0xFF3B82F6);

  /// Primary Light - Hover states
  static const Color primaryLight = Color(0xFF60A5FA);

  /// Primary Dark - Pressed states
  static const Color primaryDark = Color(0xFF2563EB);

  /// Primary Soft - Backgrounds
  static const Color primarySoft = Color(0xFF1E3A5F);

  /// Primary Glow - Effects
  static Color primaryGlow = const Color(0xFF3B82F6).withOpacity(0.4);

  /// Primary Gradient - Premium buttons & headers
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Primary Vertical Gradient
  static const LinearGradient primaryVerticalGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // SECONDARY COLORS - Emerald (Growth & Success)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Secondary Emerald - Growth & Achievement
  static const Color secondary = Color(0xFF10B981);

  /// Secondary Light
  static const Color secondaryLight = Color(0xFF34D399);

  /// Secondary Soft
  static const Color secondarySoft = Color(0xFF064E3B);

  /// Secondary Gradient
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // ACCENT COLORS - Warm Coral (Engagement & Energy)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Accent Coral - Energy & Warmth
  static const Color accent = Color(0xFFF472B6);

  /// Accent Light
  static const Color accentLight = Color(0xFFF9A8D4);

  /// Accent Soft
  static const Color accentSoft = Color(0xFF5B2341);

  /// Accent Gradient
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF472B6), Color(0xFFFB7185)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // GLASS & BLUR EFFECTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Glass Effect - White overlay
  static Color glassWhite = Colors.white.withOpacity(0.08);

  /// Glass Effect - Dark overlay
  static Color glassBlack = Colors.black.withOpacity(0.3);

  /// Glass Border
  static Color glassBorder = Colors.white.withOpacity(0.12);

  /// Glass Highlight
  static Color glassHighlight = Colors.white.withOpacity(0.05);

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT MODE COLORS (Secondary Theme)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Light Background
  static const Color background = Color(0xFFF8FAFC);

  /// Light Surface
  static const Color surface = Color(0xFFFFFFFF);

  /// Light Surface Variant
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  // Dark Theme Text
  static const Color textOnDark = Color(0xFFF8FAFC);
  static const Color textOnDarkSecondary = Color(0xFF94A3B8);
  static const Color textOnDarkHint = Color(0xFF64748B);

  // Light Theme Text
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textOnPrimary = Colors.white;

  // ═══════════════════════════════════════════════════════════════════════════
  // STATUS COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Success Green
  static const Color success = Color(0xFF10B981);
  static const Color successSoft = Color(0xFF064E3B);

  /// Warning Amber
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFF78350F);

  /// Error Red
  static const Color error = Color(0xFFEF4444);
  static const Color errorSoft = Color(0xFF7F1D1D);

  /// Info Blue
  static const Color info = Color(0xFF3B82F6);
  static const Color infoSoft = Color(0xFF1E3A5F);

  // ═══════════════════════════════════════════════════════════════════════════
  // ATTENDANCE STATUS COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color present = Color(0xFF10B981);
  static const Color absent = Color(0xFFEF4444);
  static const Color late = Color(0xFFF59E0B);
  static const Color excused = Color(0xFF3B82F6);

  // ═══════════════════════════════════════════════════════════════════════════
  // GRAY SCALE (Refined for Dark Mode)
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color gray50 = Color(0xFFF8FAFC);
  static const Color gray100 = Color(0xFFF1F5F9);
  static const Color gray200 = Color(0xFFE2E8F0);
  static const Color gray300 = Color(0xFFCBD5E1);
  static const Color gray400 = Color(0xFF94A3B8);
  static const Color gray500 = Color(0xFF64748B);
  static const Color gray600 = Color(0xFF475569);
  static const Color gray700 = Color(0xFF334155);
  static const Color gray800 = Color(0xFF1E293B);
  static const Color gray900 = Color(0xFF0F172A);

  // ═══════════════════════════════════════════════════════════════════════════
  // SPECIAL GRADIENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Premium Sunset - For highlights
  static const LinearGradient premiumSunset = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFFA726), Color(0xFFFFE082)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Premium Ocean - For professional elements
  static const LinearGradient premiumOcean = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF06B6D4), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Premium Royal - For premium features
  static const LinearGradient premiumRoyal = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFA855F7), Color(0xFFD946EF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Premium Emerald - For success states
  static const LinearGradient premiumEmerald = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF14B8A6), Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Glass Gradient - For modern glass effects
  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color.fromARGB(40, 255, 255, 255),
      Color.fromARGB(20, 255, 255, 255),
      Color.fromARGB(10, 255, 255, 255),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Neon Glow Effect
  static const List<BoxShadow> neonGlow = [
    BoxShadow(
      color: Color(0xFF3B82F6),
      blurRadius: 20,
      spreadRadius: 2,
      offset: Offset(0, 0),
    ),
    BoxShadow(
      color: Color(0xFF8B5CF6),
      blurRadius: 40,
      spreadRadius: 5,
      offset: Offset(0, 0),
    ),
  ];

  /// Soft Glow Effect
  static const List<BoxShadow> softGlow = [
    BoxShadow(
      color: Color.fromARGB(40, 59, 130, 246),
      blurRadius: 15,
      spreadRadius: 1,
      offset: Offset(0, 4),
    ),
  ];
  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [Color(0xFFF472B6), Color(0xFFFB923C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Ocean Deep - For calm sections
  static const LinearGradient oceanGradient = LinearGradient(
    colors: [Color(0xFF0EA5E9), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Success Gradient
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Card Gradient (Subtle)
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1A25), Color(0xFF12121A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // SHADOWS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Light theme shadow
  static const Color shadow = Color(0x1A1E293B);

  /// Dark theme shadow (using primary glow)
  static Color darkShadow = const Color(0xFF3B82F6).withOpacity(0.15);

  // ═══════════════════════════════════════════════════════════════════════════
  // DIVIDERS
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color divider = Color(0xFFE2E8F0);
  static const Color darkDivider = Color(0xFF2A2A3A);
}
