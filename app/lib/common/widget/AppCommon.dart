import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:time/time.dart';

Widget navBarTitle(String title) {
  return Text(
    title,
    style: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
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

String? formatedTime(int value) {
  final int h = (value.seconds.inHours + 5) % 24;
  final int m = (value.seconds.inMinutes) % 60;

  //00:00 Format
  String hour = h.toString().length < 2 ? '0' + h.toString() : h.toString();
  String minutes = m.toString().length < 2 ? '0' + m.toString() : m.toString();
  String result = '$hour:$minutes';

  return result;
}

String randomString() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}
