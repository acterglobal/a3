import 'dart:convert';
import 'dart:math';

import 'package:effektio/common/store/separatedThemes.dart';
import 'package:flutter/material.dart';

Widget navBarTitle(String title) {
  return Text(
    title,
    style: AppCommonTheme.appBartitleStyle,
  );
}

String getNameFromId(String name) {
  int start = 0, end = 0;
  if (name.contains('@')) {
    start = name.indexOf('@') + 1;
  }
  if (name.contains(':')) {
    end = name.indexOf(':');
  }
  return name.substring(start, end);
}

String randomString() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}
