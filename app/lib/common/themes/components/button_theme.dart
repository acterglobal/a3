import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:flutter/material.dart';

var elevatedButtonTheme = ElevatedButtonThemeData(
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

var outlinedButtonTheme = OutlinedButtonThemeData(
  style: OutlinedButton.styleFrom(
    padding: const EdgeInsets.all(18),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    foregroundColor: Colors.white,
    backgroundColor: Colors.transparent,
  ),
);

var textButtonTheme = TextButtonThemeData(
  style: ElevatedButton.styleFrom(
    elevation: 0,
    foregroundColor: yellowColor,
  ),
);
var iconButtonTheme = IconButtonThemeData(
  style: ButtonStyle(foregroundColor: MaterialStateProperty.all(Colors.white)),
);
