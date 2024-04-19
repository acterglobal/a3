import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:flutter/material.dart';

final elevatedButtonTheme = ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.all(18),
    elevation: 0,
    backgroundColor: greenColor,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
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

final textButtonTheme = TextButtonThemeData(
  style: ElevatedButton.styleFrom(
    elevation: 0,
    foregroundColor: yellowColor,
  ),
);
final iconButtonTheme = IconButtonThemeData(
  style: ButtonStyle(foregroundColor: MaterialStateProperty.all(Colors.white)),
);
