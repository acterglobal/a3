import 'package:effektio/common/store/themes/separatedThemes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

AppTheme currentTheme = AppTheme();

class AppTheme {
  static DividerThemeData get _dividerTheme => const DividerThemeData(
        indent: 75,
        endIndent: 15,
        thickness: 0.5,
        color: AppCommonTheme.dividerColor,
      );

  static ThemeData get theme => ThemeData(
        textTheme: GoogleFonts.robotoTextTheme(),
        scaffoldBackgroundColor: AppCommonTheme.backgroundColor,
        dividerTheme: _dividerTheme,
        appBarTheme:
            const AppBarTheme(backgroundColor: AppCommonTheme.transparentColor),
      );
}
