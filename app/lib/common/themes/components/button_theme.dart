import 'package:acter/common/themes/app_theme.dart';
import 'package:flutter/material.dart';

ElevatedButtonThemeData elevatedButtonTheme(ColorScheme colors) =>
    ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(18),
        elevation: 0,
        backgroundColor: colors.secondary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

ElevatedButtonThemeData dangerButtonThemeMaker(ColorScheme colors) =>
    ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(18),
        elevation: 0,
        backgroundColor: colors.error,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

TextButtonThemeData inlineTextButtonThemeMaker(ColorScheme colors) =>
    TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          color: Colors.white,
          decoration: TextDecoration.underline,
        ),
      ),
    );

final outlinedButtonTheme = OutlinedButtonThemeData(
  style: OutlinedButton.styleFrom(
    padding: const EdgeInsets.all(18),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    foregroundColor: Colors.white,
    backgroundColor: Colors.transparent,
  ),
);

TextButtonThemeData textButtonTheme(ColorScheme colors) => TextButtonThemeData(
      style: TextButton.styleFrom(
        elevation: 0,
        foregroundColor: colors.textButtonColor,
      ),
    );
final iconButtonTheme = IconButtonThemeData(
  style: ButtonStyle(foregroundColor: MaterialStateProperty.all(Colors.white)),
);
