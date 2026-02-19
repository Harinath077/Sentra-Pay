import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumStyle {
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardBackground = Color(0xFF1A1A1A);
  static const Color primaryText = Colors.white;
  static const Color secondaryText = Color(0xFF9CA3AF); // Soft Grey
  static const Color accentColor = Color(0xFF10B981); // Soft Green for security
  static const Color inputBorder = Color(0xFF333333);
  static const Color buttonColor = Color(0xFF10B981); // Green Button
  
  static TextStyle get headingLarge => GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: primaryText,
    letterSpacing: -1.0,
    height: 1.1,
  );

  static TextStyle get subHeading => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: secondaryText,
    letterSpacing: 0.2,
  );

  static TextStyle get inputLabel => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: secondaryText,
  );

  static TextStyle get buttonText => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static const double cardRadius = 24.0;
  static const double spacing = 24.0;
}
