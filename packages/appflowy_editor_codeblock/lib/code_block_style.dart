import 'package:flutter/material.dart';

class CodeBlockStyle {
  CodeBlockStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    this.fontSize = 12,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final double fontSize;
}
