import 'package:flutter/material.dart';

// Main Colors
Color brandColor = const Color(0xff1E4E7B);
Color darkBlueColor = const Color(0xFF042E4B);
Color lightBlueColor = const Color(0xFF06355D);
Color blackColor = const Color(0xFF121212);

// General Colors
Color greenColor = const Color(0xFF74A64D);
Color yellowColor = Colors.yellow;
Color whiteColor = const Color(0xfffbfcfd);
Color whiteBlueColor = const Color(0xFFA5B9CC);

const primaryGradient = LinearGradient(
  begin: AlignmentDirectional(-1.5, -2.0),
  end: AlignmentDirectional(-1.5, 0.5),
  colors: <Color>[
    Color(0xFF001B3D),
    Color(0xFF121212),
  ],
);

const introGradient = LinearGradient(
  colors: [
    Color(0xff122334),
    Color(0xff121212),
    Color(0xff000000),
  ],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  stops: [0.0, 0.5, 1.0],
  tileMode: TileMode.decal,
);

var colorScheme = ColorScheme.dark(
  brightness: Brightness.dark,
  primary: brandColor,
  secondary: greenColor,
  onSecondary: whiteColor,
  onPrimary: whiteColor,
  primaryContainer: darkBlueColor,
  onPrimaryContainer: whiteColor,
  secondaryContainer: blackColor,
  onSecondaryContainer: whiteColor,
  background: darkBlueColor,
  onBackground: whiteColor,
  surface: lightBlueColor,
  onSurface: whiteBlueColor,
);
