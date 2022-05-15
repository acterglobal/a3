import 'package:effektio/common/store/Colors.dart';
import 'package:effektio/common/store/Prefrences.dart';
import 'package:effektio/common/store/textTheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

AppTheme currentTheme = AppTheme();
bool isDarkTheme = true;

class AppTheme with ChangeNotifier {
  ThemeMode get currentTheme => isDarkTheme ? ThemeMode.dark : ThemeMode.light;

  Future<void> toggleTheme(bool isDark) async {
    isDarkTheme = isDark;
    await SharedPrefrence().setAppTheme(isDark);
    notifyListeners();
  }

  static DividerThemeData get _dividerTheme => const DividerThemeData(
        indent: 75,
        endIndent: 15,
        thickness: 0.5,
        color: AppColors.dividerColor,
      );

  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.primaryColor,
        textTheme: GoogleFonts.robotoTextTheme(CustomTextTheme.textTheme),
        scaffoldBackgroundColor: AppColors.lightBackgroundColor,
        dividerTheme: _dividerTheme,
        appBarTheme: const AppBarTheme(backgroundColor: AppColors.transparent),
      );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        textTheme: GoogleFonts.robotoTextTheme(CustomTextTheme.textTheme),
        scaffoldBackgroundColor: AppColors.darkBackgroundColor,
        dividerTheme: _dividerTheme,
        appBarTheme: const AppBarTheme(backgroundColor: AppColors.transparent),
      );
}
