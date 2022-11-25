import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:flutter/material.dart';

Widget noInternetWidget() {
  return Center(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/no_internet.png',
          scale: 5,
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
