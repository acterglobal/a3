import 'dart:io';

import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/themes/components/text_theme.dart';
import 'package:flutter/material.dart';

ElevatedButtonThemeData elevatedButtonTheme() => ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    padding: EdgeInsets.symmetric(
      horizontal: 16,
      vertical: Platform.isAndroid || Platform.isIOS ? 12 : 16,
    ),
    elevation: 0,
    textStyle: textTheme.titleMedium?.copyWith(
      color: colorScheme.primary,
      fontSize: 15,
    ),
    backgroundColor: colorScheme.primary,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
);

ElevatedButtonThemeData dangerButtonThemeMaker() => ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    elevation: 0,
    textStyle: textTheme.titleMedium?.copyWith(
      color: colorScheme.primary,
      fontSize: 15,
    ),
    backgroundColor: colorScheme.error,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
);

TextButtonThemeData inlineTextButtonThemeMaker() => TextButtonThemeData(
  style: TextButton.styleFrom(
    foregroundColor: Colors.white,
    textStyle: const TextStyle(
      color: Colors.white,
      decoration: TextDecoration.underline,
    ),
  ),
);

OutlinedButtonThemeData outlinedButtonTheme() => OutlinedButtonThemeData(
  style: OutlinedButton.styleFrom(
    side: BorderSide(color: colorScheme.outline),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    padding: EdgeInsets.symmetric(
      horizontal: 12,
      vertical: Platform.isAndroid || Platform.isIOS ? 6 : 16,
    ),
    textStyle: textTheme.titleMedium?.copyWith(fontSize: 15),
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  ),
);

TextButtonThemeData textButtonTheme() => TextButtonThemeData(
  style: TextButton.styleFrom(
    elevation: 0,
    iconColor: colorScheme.onSurface,
    foregroundColor: colorScheme.onSurface,
  ),
);
final iconButtonTheme = IconButtonThemeData(
  style: ButtonStyle(
    iconColor: WidgetStateProperty.all(whiteColor),
    foregroundColor: WidgetStateProperty.all(whiteColor),
  ),
);
