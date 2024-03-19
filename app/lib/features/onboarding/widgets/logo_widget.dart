import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  final double height;
  final double width;

  const LogoWidget({
    super.key,
    this.height = 200,
    this.width = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icon/logo_foreground.png',
      height: height,
      width: width,
    );
  }
}
