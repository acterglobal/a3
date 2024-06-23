import 'package:flutter/material.dart';

// Main Colors
Color brandColor = const Color(0xff1E4E7B);
Color secondaryColor = const Color(0xFF74A64D);

// Background Colors
Color surfaceColor = const Color(0xFF2A2A2A);
Color backgroundColor = const Color(0xFF171717);

//On colors
Color whiteColor = Colors.white;

var colorScheme = ColorScheme.dark(
  brightness: Brightness.dark,
  //Primary
  primary: brandColor,
  onPrimary: whiteColor,

  //Secondary
  secondary: secondaryColor,
  onSecondary: whiteColor,

  //Primary Container
  primaryContainer: surfaceColor,
  onPrimaryContainer: whiteColor,

  //Secondary Container
  secondaryContainer: backgroundColor,
  onSecondaryContainer: whiteColor,

  //Surface
  surface: surfaceColor,
  onSurface: whiteColor,
);
extension CustomColorScheme on ColorScheme {
  // brand
  Color get textHighlight => secondary;

  Color get textColor => whiteColor;

  // states
  Color get success => secondary;

  // specific widgets
  Color get badgeUnread => secondary;

  Color get badgeImportant => Colors.yellow;

  Color get badgeUrgent => const Color(0xFF93000A);
}