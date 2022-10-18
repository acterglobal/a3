import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

AppTheme currentTheme = AppTheme();

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      textTheme: GoogleFonts.robotoTextTheme(),
      scaffoldBackgroundColor: AppCommonTheme.backgroundColor,
      dividerTheme: const DividerThemeData(
        indent: 75,
        endIndent: 15,
        thickness: 0.5,
        color: AppCommonTheme.dividerColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppCommonTheme.transparentColor,
      ),
    );
  }
}
