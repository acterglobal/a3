import 'dart:io' show Platform;
import 'package:effektio/common/themes/seperated_themes.dart';
import 'package:flutter/material.dart';

Widget noInternetWidget() {
  Size screenSize = WidgetsBinding.instance.window.physicalSize;
  bool isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  double width = screenSize.width;
  double height = screenSize.height;
  return Center(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Image.asset(
            'assets/images/no_internet.png',
            cacheHeight:
                isDesktop ? (height * 0.25).toInt() : (height * 0.10).toInt(),
            cacheWidth:
                isDesktop ? (width * 0.15).toInt() : (height * 0.10).toInt(),
            filterQuality: FilterQuality.high,
          ),
        ),
        const Text(
          'No internet\nPlease turn on internet to process',
          style: SideMenuAndProfileTheme.profileMenuStyle,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
