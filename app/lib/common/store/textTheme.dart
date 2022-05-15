import 'package:flutter/material.dart';

class CustomTextTheme {
  static TextTheme get textTheme => const TextTheme(
        titleSmall: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w700,
        ),
      );
}
