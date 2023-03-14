import 'package:acter/common/themes/seperated_themes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

AppTheme currentTheme = AppTheme();

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      textTheme: GoogleFonts.interTextTheme(),
      splashColor: Colors.transparent,
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
        backgroundColor: Color(0xff122D46),
        unselectedLabelStyle: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        selectedLabelStyle: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        selectedIconTheme: IconThemeData(color: Colors.white, size: 20),
        unselectedIconTheme: IconThemeData(color: Colors.white, size: 20),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Color(0xff122D46),
        indicatorColor: Color(0xff1E4E7B),
        unselectedLabelTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        selectedLabelTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        selectedIconTheme: IconThemeData(color: Colors.white, size: 20),
        unselectedIconTheme: IconThemeData(color: Colors.white, size: 20),
      ),
    );
  }
}
