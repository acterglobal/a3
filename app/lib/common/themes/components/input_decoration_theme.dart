import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:flutter/material.dart';

var inputDecorationTheme = InputDecorationTheme(
  fillColor: surfaceColor,
  filled: true,
  focusedBorder: OutlineInputBorder(
    borderSide: const BorderSide(color: Colors.white70),
    borderRadius: BorderRadius.circular(12),
  ),
  enabledBorder: OutlineInputBorder(
    borderSide: const BorderSide(color: Colors.white30),
    borderRadius: BorderRadius.circular(12),
  ),
  border: OutlineInputBorder(
    borderSide: BorderSide.none,
    borderRadius: BorderRadius.circular(12),
  ),
  errorBorder: OutlineInputBorder(
    borderSide: const BorderSide(color: Colors.red),
    borderRadius: BorderRadius.circular(12),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderSide: const BorderSide(color: Colors.red),
    borderRadius: BorderRadius.circular(12),
  ),
  hintStyle: const TextStyle(
    color: Color(0xFF898989),
    fontWeight: FontWeight.w300,
    fontSize: 14,
  ),
);
