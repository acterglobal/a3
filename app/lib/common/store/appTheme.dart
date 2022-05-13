import 'package:effektio/common/store/Colors.dart';
import 'package:effektio/common/store/textTheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        textTheme: GoogleFonts.robotoTextTheme(CustomTextTheme.textTheme),
        // drawerTheme: DrawerThemeData(backgroundColor: AppColors.backgroundColor),
      );
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        textTheme: GoogleFonts.robotoTextTheme(CustomTextTheme.textTheme),
        // drawerTheme: DrawerThemeData(backgroundColor: AppColors.backgroundColor),
      );
}
