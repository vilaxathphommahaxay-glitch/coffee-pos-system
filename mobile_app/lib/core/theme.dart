import 'package:flutter/material.dart';

// 🎨 --- ILa HomeBar & Coffee Palette ---
const Color bgCream = Color(0xFFF9F6F0);
const Color earthBrown = Color(0xFF5D4037);
const Color mossGreen = Color(0xFF6B705C);
const Color softBlack = Color(0xFF2C2C2C);
const Color paperWhite = Color(0xFFFFFFFF);
const Color borderColor = Color(0xFFE8E4D9);
const Color mutedText = Color(0xFF8D8D8D);

// ☕ Midnight Roast Palette (Endgame)
const Color midnightBlack = Color(0xFF121212);
const Color midnightSurface = Color(0xFF1E1E1E);
const Color copperAccent = Color(0xFFD4A373);
const Color amberAccent = Color(0xFFFFB347);
const Color textPrimaryDark = Color(0xFFEAEAEA);
const Color textSecondaryDark = Color(0xFFB0B0B0);

class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light, 
      scaffoldBackgroundColor: bgCream, 
      fontFamily: 'serif',
      appBarTheme: const AppBarTheme(
        backgroundColor: bgCream, 
        elevation: 0, 
        scrolledUnderElevation: 0, 
        iconTheme: IconThemeData(color: softBlack), 
        titleTextStyle: TextStyle(color: softBlack, fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0.5)
      ),
      colorScheme: const ColorScheme.light(
        primary: earthBrown, 
        secondary: mossGreen, 
        surface: paperWhite, 
        onSurface: softBlack, 
        outline: borderColor, 
        onSurfaceVariant: mutedText
      ),
      useMaterial3: true,
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark, 
      scaffoldBackgroundColor: midnightBlack, 
      fontFamily: 'serif',
      appBarTheme: const AppBarTheme(
        backgroundColor: midnightBlack, 
        elevation: 0, 
        scrolledUnderElevation: 0, 
        iconTheme: IconThemeData(color: copperAccent), 
        titleTextStyle: TextStyle(color: copperAccent, fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0.5)
      ),
      colorScheme: const ColorScheme.dark(
        primary: copperAccent, 
        secondary: amberAccent, 
        surface: midnightSurface, 
        onSurface: textPrimaryDark, 
        outline: Color(0xFF333333), 
        onSurfaceVariant: textSecondaryDark,
        background: midnightBlack
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: copperAccent,
          foregroundColor: midnightBlack,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        )
      ),
      useMaterial3: true,
    );
  }
}
