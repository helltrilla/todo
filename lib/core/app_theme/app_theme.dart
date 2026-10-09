import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    primaryColor: const Color(0xFF242424),
    cardColor: const Color(0xFF1E1E1E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      elevation: 0,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF121212),
      constraints: BoxConstraints(maxWidth: 640),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF242424)),
    datePickerTheme: const DatePickerThemeData(),
    textTheme: GoogleFonts.interTextTheme(
      const TextTheme(
        titleMedium: TextStyle(
          fontSize: 30,
          fontStyle: FontStyle.italic,
          color: Colors.white,
        ),
      ),
    ),
  );

  static ThemeData get midnight => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF000000),
    primaryColor: const Color(0xFF101010),
    cardColor: const Color(0xFF0D0D0E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF000000),
      elevation: 0,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF000000),
      constraints: BoxConstraints(maxWidth: 640),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF101010)),
    datePickerTheme: const DatePickerThemeData(),
    textTheme: GoogleFonts.interTextTheme(
      const TextTheme(
        titleMedium: TextStyle(
          fontSize: 30,
          fontStyle: FontStyle.italic,
          color: Colors.white,
        ),
      ),
    ),
  );

  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F6F9),
    primaryColor: const Color(0xFFFFFFFF),
    cardColor: const Color(0xFFFFFFFF),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF5F6F9),
      elevation: 0,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFFFFFFFF),
      constraints: BoxConstraints(maxWidth: 640),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: Color(0xFFFFFFFF)),
    datePickerTheme: const DatePickerThemeData(),
    textTheme: GoogleFonts.interTextTheme(
      const TextTheme(
        titleMedium: TextStyle(
          fontSize: 30,
          fontStyle: FontStyle.italic,
          color: Color(0xFF18191B),
        ),
      ),
    ),
  );
}
