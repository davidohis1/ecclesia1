import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF6B4EFF);       // Royal Purple
  static const Color primaryLight = Color(0xFF9B7FFF);
  static const Color primaryDark = Color(0xFF3D1FCC);
  static const Color accent = Color(0xFFFFD700);        // Gold
  static const Color accentLight = Color(0xFFFFE866);
  static const Color rose = Color(0xFFFF6B8A);
  static const Color teal = Color(0xFF00D4AA);
  
  // Backgrounds
  static const Color bgDark = Color(0xFF0A0A14);
  static const Color bgCard = Color(0xFF13131F);
  static const Color bgSurface = Color(0xFF1A1A2E);
  static const Color bgElevated = Color(0xFF22223A);
  
  // Text
  static const Color textPrimary = Color(0xFFF8F8FF);
  static const Color textSecondary = Color(0xFFAAAAAF);
  static const Color textMuted = Color(0xFF666680);
  
  // Semantic
  static const Color success = Color(0xFF00E676);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFD740);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: bgCard,
        background: bgDark,
        error: error,
        onPrimary: Colors.white,
        onSecondary: bgDark,
        onSurface: textPrimary,
        onBackground: textPrimary,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 26, fontWeight: FontWeight.bold, color: textPrimary,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary,
        ),
        headlineMedium: GoogleFonts.dmSans(
          fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary,
        ),
        titleLarge: GoogleFonts.dmSans(
          fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary,
        ),
        bodyLarge: GoogleFonts.dmSans(fontSize: 15, color: textPrimary),
        bodyMedium: GoogleFonts.dmSans(fontSize: 14, color: textSecondary),
        labelLarge: GoogleFonts.dmSans(
          fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: 0.5,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.dmSans(color: textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgCard,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }
}

// Post background colors for text posts
class PostBackgrounds {
  static const List<Map<String, dynamic>> gradients = [
    {
      'id': 'none',
      'label': 'None',
      'colors': <Color>[],
    },
    {
      'id': 'sunrise',
      'label': 'Sunrise',
      'colors': [Color(0xFFFF6B6B), Color(0xFFFFD93D)],
    },
    {
      'id': 'ocean',
      'label': 'Ocean',
      'colors': [Color(0xFF0575E6), Color(0xFF021B79)],
    },
    {
      'id': 'forest',
      'label': 'Forest',
      'colors': [Color(0xFF56AB2F), Color(0xFFA8E063)],
    },
    {
      'id': 'royal',
      'label': 'Royal',
      'colors': [Color(0xFF6B4EFF), Color(0xFF3D1FCC)],
    },
    {
      'id': 'gold',
      'label': 'Gold',
      'colors': [Color(0xFFFFD700), Color(0xFFFF8C00)],
    },
    {
      'id': 'midnight',
      'label': 'Midnight',
      'colors': [Color(0xFF232526), Color(0xFF414345)],
    },
    {
      'id': 'heaven',
      'label': 'Heaven',
      'colors': [Color(0xFFE0C3FC), Color(0xFF8EC5FC)],
    },
  ];
}