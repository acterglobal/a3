import 'package:acter/common/themes/seperated_themes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

AppTheme currentTheme = AppTheme();

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      typography: Typography(
        black: GoogleFonts.interTextTheme(
          const TextTheme(
            headlineLarge: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
            headlineMedium: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
            headlineSmall: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            titleLarge: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.normal,
            ),
            titleMedium: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.normal,
            ),
            titleSmall: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.normal,
            ),
            bodyLarge: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
            bodyMedium: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            bodySmall: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            labelLarge: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
            labelMedium: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w300,
            ),
            labelSmall: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: Colors.white,
        splashColor: Colors.transparent,
      ),
      splashColor: Colors.transparent,
      useMaterial3: true,
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
          height: 1.5,
        ),
        selectedIconTheme: IconThemeData(color: Colors.white, size: 18),
        unselectedIconTheme: IconThemeData(color: Colors.white, size: 18),
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
        selectedIconTheme: IconThemeData(color: Colors.white, size: 18),
        unselectedIconTheme: IconThemeData(color: Colors.white, size: 18),
      ),
    );
  }
}
