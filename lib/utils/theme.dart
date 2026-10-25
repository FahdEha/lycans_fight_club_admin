import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppConstants.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppConstants.gold,
        secondary: AppConstants.goldSoft,
        surface: AppConstants.bgCard,
        error: AppConstants.ember,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.oswald(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: AppConstants.ink,
        ),
        titleLarge: GoogleFonts.oswald(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: AppConstants.ink,
        ),
        titleMedium: GoogleFonts.oswald(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: AppConstants.ink,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 12.5,
          color: AppConstants.ink,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 11.5,
          color: AppConstants.inkDim,
        ),
        bodySmall: GoogleFonts.manrope(
          fontSize: 10.5,
          color: AppConstants.inkFaint,
        ),
        labelLarge: GoogleFonts.jetBrainsMono(
          fontSize: 10.5,
          letterSpacing: 0.1,
          color: AppConstants.goldSoft,
        ),
        labelMedium: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          letterSpacing: 0.08,
          color: AppConstants.inkDim,
        ),
      ),
    );
  }
}