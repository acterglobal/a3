import 'package:flutter/material.dart';

// Main Colors
Color brandColor = const Color(0xff126bab);
Color secondaryColor = const Color(0xFF74A64D);

// Background Colors
Color greyColor = Colors.grey.shade800;
Color surfaceColor = const Color(0xff181c1f);
Color backgroundColor = const Color(0xff0d0f11);

//On colors
Color whiteColor = Colors.white;

Color pinFeatureColor = const Color(0xff7c4a4a);
Color eventFeatureColor = const Color(0xff206a9a);
Color taskFeatureColor = const Color(0xff406c6e);
Color boastFeatureColor = Colors.blueGrey;

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

  Color get badgeUrgent => const Color.fromARGB(255, 236, 44, 57);
}
