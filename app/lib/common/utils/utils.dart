import 'dart:convert';
import 'dart:math';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter/material.dart';

String randomString() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}

int hexOfRGBA(int r, int g, int b, {double opacity = 1}) {
  r = (r < 0) ? -r : r;
  g = (g < 0) ? -g : g;
  b = (b < 0) ? -b : b;
  opacity = (opacity < 0) ? -opacity : opacity;
  opacity = (opacity > 1) ? 255 : opacity * 255;
  r = (r > 255) ? 255 : r;
  g = (g > 255) ? 255 : g;
  b = (b > 255) ? 255 : b;
  int a = opacity.toInt();
  return int.parse(
    '0x${a.toRadixString(16)}${r.toRadixString(16)}${g.toRadixString(16)}${b.toRadixString(16)}',
  );
}

bool isOnlyEmojis(String text) {
  final emojisRegExp = RegExp(
    r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])',
  );
  // find all emojis
  final emojis = emojisRegExp.allMatches(text);

  // return if none found
  if (emojis.isEmpty) return false;

  // remove all emojis from the this
  for (final emoji in emojis) {
    text = text.replaceAll(emoji.input.substring(emoji.start, emoji.end), '');
  }

  // remove all whitespace (optional)
  text = text.replaceAll('', '');

  // return true if nothing else left
  return text.isEmpty;
}

extension DateHelpers on DateTime {
  bool isToday() {
    final now = DateTime.now();
    return now.day == day && now.month == month && now.year == year;
  }

  bool isYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return yesterday.day == day &&
        yesterday.month == month &&
        yesterday.year == year;
  }
}

String? simplifyUserId(String name) {
  RegExp re = RegExp(r'^@(.*):\w+([\.-]?\w+)*(\.\w+)+$');
  RegExpMatch? m1 = re.firstMatch(name);
  if (m1 != null) {
    String? userId = m1.group(1);
    if (userId != null) {
      // replace symbol with string
      return userId.replaceAllMapped(RegExp(r'=([0-9a-fA-F]{2})'), (m2) {
        int charCode = int.parse('0x${m2.group(1)}');
        return String.fromCharCode(charCode);
      });
    }
  }
  return null;
}

String? simplifyRoomId(String name) {
  RegExp re = RegExp(r'^!(\w+([\.-]?\w+)*):\w+([\.-]?\w+)*(\.\w+)+$');
  RegExpMatch? match = re.firstMatch(name);
  if (match != null) {
    return match.group(1);
  }
  return name;
}

String simplifyBody(String formattedBody) {
  // strip out parent msg from reply msg
  RegExp re = RegExp(r'^<mx-reply>[\s\S]+</mx-reply>');
  return formattedBody.replaceAll(re, '');
}

Color getUserAvatarNameColor(types.User user, List<Color> colors) =>
    colors[user.id.hashCode % colors.length];

String getUserInitials(types.User user) {
  var initials = '';

  if ((user.firstName ?? '').isNotEmpty) {
    initials += user.firstName![0].toUpperCase();
  }

  if ((user.lastName ?? '').isNotEmpty) {
    initials += user.lastName![0].toUpperCase();
  }

  return initials.trim();
}
