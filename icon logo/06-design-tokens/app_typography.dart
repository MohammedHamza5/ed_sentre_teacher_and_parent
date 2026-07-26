import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// EdSentre typography system.
/// Cairo — primary Arabic typeface. Space Grotesk — English & numerals.
/// Requires the google_fonts package and app_colors.dart in the same project.
class AppTypography {
  AppTypography._();

  // Cairo — Arabic
  static TextStyle get h1 =>
      GoogleFonts.cairo(fontSize: 56, fontWeight: FontWeight.w900, height: 1);
  static TextStyle get h2 =>
      GoogleFonts.cairo(fontSize: 40, fontWeight: FontWeight.w800);
  static TextStyle get h3 =>
      GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.w700);
  // static TextStyle get body => GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.gray300);
  static TextStyle get small => GoogleFonts.cairo(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.gray500,
  );

  // Space Grotesk — English & numbers
  static TextStyle get h1En => GoogleFonts.spaceGrotesk(
    fontSize: 56,
    fontWeight: FontWeight.w700,
    height: 1,
  );
  static TextStyle get h2En => GoogleFonts.spaceGrotesk(
    fontSize: 40,
    fontWeight: FontWeight.w600,
    color: AppColors.teal,
  );
  // static TextStyle get bodyEn => GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.gray300);
  static TextStyle get label => GoogleFonts.spaceGrotesk(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.teal,
    letterSpacing: 3,
  );
  static TextStyle get cta => GoogleFonts.spaceGrotesk(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.navyCore,
  );
}
