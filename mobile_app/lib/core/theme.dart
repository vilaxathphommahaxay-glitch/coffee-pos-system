import 'package:flutter/material.dart';

// 🎨 --- ILa HomeBar & Coffee Palette ---
const Color bgCream = Color(0xFFF9F6F0);
const Color earthBrown = Color(0xFF5D4037);
const Color mossGreen = Color(0xFF6B705C);
const Color softBlack = Color(0xFF2C2C2C);
const Color paperWhite = Color(0xFFFFFFFF);
const Color borderColor = Color(0xFFE8E4D9);
const Color mutedText = Color(0xFF8D8D8D);

const Color bgBaseDark = Color(0xFF1A1817);
const Color surfaceDark = Color(0xFF242220); 
const Color earthBrownDark = Color(0xFFD4B895); 
const Color mossGreenDark = Color(0xFF8BA372); 
const Color softBlackDark = Color(0xFFF9F6F0);
const Color borderColorDark = Color(0xFF383431); 
const Color mutedTextDark = Color(0xFF8A847D);

class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light, scaffoldBackgroundColor: bgCream, fontFamily: 'serif',
      appBarTheme: const AppBarTheme(backgroundColor: bgCream, elevation: 0, scrolledUnderElevation: 0, iconTheme: IconThemeData(color: softBlack), titleTextStyle: TextStyle(color: softBlack, fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      colorScheme: const ColorScheme.light(primary: earthBrown, secondary: mossGreen, surface: paperWhite, onSurface: softBlack, outline: borderColor, onSurfaceVariant: mutedText),
      useMaterial3: true,
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark, scaffoldBackgroundColor: bgBaseDark, fontFamily: 'serif',
      appBarTheme: const AppBarTheme(backgroundColor: bgBaseDark, elevation: 0, scrolledUnderElevation: 0, iconTheme: IconThemeData(color: softBlackDark), titleTextStyle: TextStyle(color: softBlackDark, fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      colorScheme: const ColorScheme.dark(primary: earthBrownDark, secondary: mossGreenDark, surface: surfaceDark, onSurface: softBlackDark, outline: borderColorDark, onSurfaceVariant: mutedTextDark),
      useMaterial3: true,
    );
  }
}
