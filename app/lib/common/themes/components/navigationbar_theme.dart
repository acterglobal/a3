import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:flutter/material.dart';

var bottomNavigationBarTheme =  BottomNavigationBarThemeData(
  backgroundColor: darkBlueColor,
  unselectedLabelStyle: const TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  ),
  selectedItemColor: Colors.white,
  unselectedItemColor: Colors.white,
  selectedLabelStyle: const TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  ),
  selectedIconTheme: const IconThemeData(color: Colors.white, size: 18),
  unselectedIconTheme: const IconThemeData(color: Colors.white, size: 18),
  type: BottomNavigationBarType.fixed,
  elevation: 0,
);

var navigationRailTheme =  NavigationRailThemeData(
  backgroundColor: darkBlueColor,
  indicatorColor: brandColor,
  unselectedLabelTextStyle: const TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  ),
  selectedLabelTextStyle: const TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  ),
  selectedIconTheme: const IconThemeData(color: Colors.white, size: 18),
  unselectedIconTheme: const IconThemeData(color: Colors.white, size: 18),
);
