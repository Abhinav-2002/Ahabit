import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  final Box _settingsBox = Hive.box('settings');

  ThemeMode _themeMode = ThemeMode.light;

  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void _loadTheme() {
    final isDark = _settingsBox.get(_themeKey, defaultValue: false);
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _settingsBox.put(_themeKey, _themeMode == ThemeMode.dark);
    notifyListeners();
  }

  void setDarkMode(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _settingsBox.put(_themeKey, isDark);
    notifyListeners();
  }

  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      primaryColor: const Color(0xFF111111),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF111111),
        secondary: Color(0xFFC8F53C),
        surface: Colors.white,
        background: Color(0xFFF5F5F7),
        onPrimary: Colors.white,
        onSecondary: Color(0xFF111111),
        onSurface: Color(0xFF111111),
        onBackground: Color(0xFF111111),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF111111)),
        displayMedium: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFF111111)),
        displaySmall: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF111111)),
        headlineMedium: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF111111)),
        headlineSmall: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF111111)),
        titleLarge: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF111111)),
        titleMedium: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111111)),
        bodyLarge: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF111111)),
        bodyMedium: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFF888888)),
        bodySmall: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xFFAAAAAA)),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFFF5F5F7),
        titleTextStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF111111)),
        iconTheme: const IconThemeData(color: Color(0xFF111111)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF111111),
        unselectedItemColor: const Color(0xFFAAAAAA),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600),
      ),
      fontFamily: GoogleFonts.dmSans().fontFamily,
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      primaryColor: const Color(0xFFC8F53C),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFC8F53C),
        secondary: Color(0xFF2C2C2E),
        surface: Color(0xFF2C2C2E),
        background: Color(0xFF1A1A1A),
        onPrimary: Color(0xFF111111),
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
        displayMedium: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
        displaySmall: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
        headlineMedium: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
        headlineSmall: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
        titleLarge: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
        titleMedium: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
        bodyMedium: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFF888888)),
        bodySmall: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xFF666666)),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF2C2C2E),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1A1A),
        titleTextStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF2C2C2E),
        selectedItemColor: const Color(0xFFC8F53C),
        unselectedItemColor: const Color(0xFF666666),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600),
      ),
      fontFamily: GoogleFonts.dmSans().fontFamily,
    );
  }
}
