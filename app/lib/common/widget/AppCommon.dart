import 'dart:convert';
import 'dart:math';

import 'package:effektio/common/store/separatedThemes.dart';
import 'package:flutter/material.dart';

Widget navBarTitle(String title) {
  return Text(
    title,
    style: AppCommonTheme.appBarTitleStyle,
  );
}

String? getNameFromId(String name) {
  RegExp re = RegExp(r'^@(\w+([\.-]?\w+)*):\w+([\.-]?\w+)*(\.\w{2,3})+$');
  RegExpMatch? match = re.firstMatch(name);
  if (match != null) {
    return match.group(1);
  }
  return null;
}

String randomString() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}

Widget elevatedButton(
  String title,
  Color color,
  VoidCallback? callback,
  TextStyle textstyle,
) {
  return ElevatedButton(
    onPressed: callback,
    style: ElevatedButton.styleFrom(
      primary: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    child: Text(title, style: textstyle),
  );
}
