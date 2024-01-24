import 'package:flutter/material.dart';


//Main Colors
Color brandColor = const Color(0xff1E4E7B);
Color darkBlueColor = const Color(0xFF042E4B);
Color lightBlueColor = const Color(0xFF06355D);
Color blackColor = const Color(0xFF121212);

//General Colors
Color greenColor = const Color(0xFF74A64D);
Color yellowColor =  Colors.yellow;
Color whiteColor = const Color(0xfffbfcfd);

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
  onSurface: whiteColor,
);
