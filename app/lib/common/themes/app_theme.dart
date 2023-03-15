import 'package:acter/common/themes/seperated_themes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

AppTheme currentTheme = AppTheme();

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      textTheme: GoogleFonts.robotoTextTheme(),
      useMaterial3: true,
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
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppCommonTheme.backgroundColor,
        selectedItemColor: AppCommonTheme.primaryColor,
        unselectedItemColor: AppCommonTheme.svgIconColor,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppCommonTheme.backgroundColor,
        indicatorColor: Color(0x1EE8DEF8),
      ),
    );
  }
}
