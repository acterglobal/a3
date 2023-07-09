import 'dart:convert';
import 'dart:math';
import 'dart:async';

import 'package:acter/common/utils/constants.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:riverpod/riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

/// An extension on [Ref] with helpful methods to add a debounce.
extension RefDebounceExtension on Ref {
  /// Delays an execution by a bit such that if a dependency changes multiple
  /// time rapidly, the rest of the code is only run once.
  Future<void> debounce(Duration duration) {
    final completer = Completer<void>();
    final timer = Timer(duration, () {
      if (!completer.isCompleted) completer.complete();
    });
    onDispose(() {
      timer.cancel();
      if (!completer.isCompleted) {
        completer.completeError(StateError('Cancelled'));
      }
    });
    return completer.future;
  }
}

DateTime kFirstDay = DateTime.utc(2010, 10, 16);
DateTime kLastDay = DateTime.utc(2050, 12, 31);

List<CalendarEvent> eventsForDay(List<CalendarEvent> events, DateTime day) {
  return events.where((e) {
    final startDay = toDartDatetime(e.utcStart());
    final endDay = toDartDatetime(e.utcEnd());
    return (startDay.difference(day).inDays == 0) ||
        (endDay.difference(day).inDays == 0);
  }).toList();
}

String formatDt(CalendarEvent e) {
  final start = toDartDatetime(e.utcStart());
  final end = toDartDatetime(e.utcEnd());
  if (e.showWithoutTime()) {
    final startFmt = DateFormat.yMMMd().format(start);
    if (start.difference(end).inDays == 0) {
      return startFmt;
    } else {
      final endFmt = DateFormat.yMMMd().format(end);
      return '$startFmt - $endFmt';
    }
  } else {
    final startFmt = DateFormat.yMMMd().format(start);
    final startTimeFmt = DateFormat.Hm().format(start);
    final endTimeFmt = DateFormat.Hm().format(end);

    if (start.difference(end).inDays == 0) {
      return '$startFmt $startTimeFmt - $endTimeFmt';
    } else {
      final endFmt = DateFormat.yMMMd().format(end);
      return '$startFmt $startTimeFmt - $endFmt $endTimeFmt';
    }
  }
}

Future<bool> openLink(String target, BuildContext context) async {
  final Uri? url = Uri.tryParse(target);
  if (url == null || !url.hasAuthority) {
    debugPrint('Opening internally: $url');
    // not a valid URL, try local routing
    await context.push(target);
    return true;
  } else {
    debugPrint('Opening external URL: $url');
    return await launchUrl(url);
  }
}

bool isDesktop(BuildContext context) {
  return desktopPlatforms.contains(Theme.of(context).platform);
}

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
  // example - @bitfriend:acter.global
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
  // example - !qporfwt:matrix.org
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

Color getUserAvatarNameColor(types.User user, List<Color> colors) {
  return colors[user.id.hashCode % colors.length];
}

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

String? getIssueId(String url) {
  // example - https://github.com/bitfriend/acter-bugs/issues/9
  RegExp re = RegExp(r'^https:\/\/github.com\/(.*)\/(.*)\/issues\/(\d*)$');
  RegExpMatch? match = re.firstMatch(url);
  if (match != null) {
    return match.group(3);
  }
  return null;
}

///helper function to convert list ffiString object to DartString.
List<String>? asDartStringList(List<FfiString> list) {
  if (list.isNotEmpty) {
    final List<String> stringList =
        list.map((ffiString) => ffiString.toDartString()).toList();
    return stringList;
  }
  return null;
}

// ignore: constant_identifier_names
enum NetworkStatus { NotDetermined, On, Off }

enum LabsFeature {
  // apps in general
  tasks,
  events,
  notes,
  pins,
  cobudget,
  polls,
  discussions,

  // searchOptions
  searchSpaces,
  ;

  static List<LabsFeature> get defaults =>
      [LabsFeature.events, LabsFeature.pins];
}
