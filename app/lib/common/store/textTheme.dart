import 'package:flutter/material.dart';

class CustomTextTheme {
  //bodyMedium: User Id
  static TextTheme get textTheme => const TextTheme(
    /// sidebar menue item
    titleSmall: TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 15,
    ),
    /// User Name
    titleMedium: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 18,
    ),
    titleLarge: TextStyle(
      fontWeight: FontWeight.w700,
    ),
  );
}
