import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:flutter/material.dart';

ElevatedButtonThemeData elevatedButtonTheme(ColorScheme colors) =>
    ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(18),
        elevation: 0,
        backgroundColor: colors.primary,
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
        iconColor: colors.onSurface,
        foregroundColor: colors.onSurface,
      ),
    );
final iconButtonTheme = IconButtonThemeData(
  style: ButtonStyle(
    iconColor: WidgetStateProperty.all(whiteColor),
    foregroundColor: WidgetStateProperty.all(whiteColor),
  ),
);
