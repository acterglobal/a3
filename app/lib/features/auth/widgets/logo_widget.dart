import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LogoWidget extends StatelessWidget {
  final double height;
  final double width;

  const LogoWidget({super.key, this.height = 200, this.width = 200});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icon/logo_foreground.svg',
      height: height,
      width: width,
    );
  }
}
