// ignore_for_file: unnecessary_null_comparison

import 'dart:convert';
import 'dart:math';
import 'dart:async';

import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/rendering.dart';
import 'package:jiffy/jiffy.dart';
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
  final start = toDartDatetime(e.utcStart()).toLocal();
  final end = toDartDatetime(e.utcEnd()).toLocal();
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
    final startTimeFmt = DateFormat('hh:mm a').format(start);
    final endTimeFmt = DateFormat('hh:mm a').format(end);

    if (start.difference(end).inDays == 0) {
      return '$startFmt $startTimeFmt - $endTimeFmt';
    } else {
      final endFmt = DateFormat.yMMMd().format(end);
      return '$startFmt $startTimeFmt - $endFmt $endTimeFmt';
    }
  }
}

String jiffyTime(int timeInterval) {
  final jiffyTime = Jiffy.parseFromMillisecondsSinceEpoch(timeInterval);
  final now = Jiffy.now().startOf(Unit.day);
  if (now.isSame(jiffyTime, unit: Unit.day)) {
    // (00:00 AM/PM)
    return jiffyTime.jm;
  } else {
    final yesterday = now.subtract(days: 1);
    final week = now.subtract(weeks: 1);
    if (jiffyTime.isBetween(yesterday, now)) {
      return 'Yesterday';
    } else if (jiffyTime.isBetween(week, now)) {
      return jiffyTime.EEEE;
    } else {
      return jiffyTime.yMd;
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
List<String> asDartStringList(FfiListFfiString data) {
  if (data.isEmpty) {
    return [];
  }
  return data.toList().map((e) => e.toDartString()).toList();
}

// ignore: constant_identifier_names
enum NetworkStatus { NotDetermined, On, Off }

// ignore: constant_identifier_names
enum RoomVisibility { Public, Private, SpaceVisible }

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
  showNotifications,
  ;

  static List<LabsFeature> get defaults =>
      [LabsFeature.events, LabsFeature.pins];
}

class SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight
    extends SliverGridDelegate {
  /// Creates a delegate that makes grid layouts with a fixed number of tiles in
  /// the cross axis.
  ///
  /// All of the arguments must not be null. The `mainAxisSpacing` and
  /// `crossAxisSpacing` arguments must not be negative. The `crossAxisCount`
  /// and `childAspectRatio` arguments must be greater than zero.
  const SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight({
    required this.crossAxisCount,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.height = 56.0,
  })  : assert(crossAxisCount != null && crossAxisCount > 0),
        assert(mainAxisSpacing != null && mainAxisSpacing >= 0),
        assert(crossAxisSpacing != null && crossAxisSpacing >= 0),
        assert(height != null && height > 0);

  /// The number of children in the cross axis.
  final int crossAxisCount;

  /// The number of logical pixels between each child along the main axis.
  final double mainAxisSpacing;

  /// The number of logical pixels between each child along the cross axis.
  final double crossAxisSpacing;

  /// The height of the crossAxis.
  final double height;

  bool _debugAssertIsValid() {
    assert(crossAxisCount > 0);
    assert(mainAxisSpacing >= 0.0);
    assert(crossAxisSpacing >= 0.0);
    assert(height > 0.0);
    return true;
  }

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    assert(_debugAssertIsValid());
    final double usableCrossAxisExtent =
        constraints.crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1);
    final double childCrossAxisExtent = usableCrossAxisExtent / crossAxisCount;
    final double childMainAxisExtent = height;
    return SliverGridRegularTileLayout(
      crossAxisCount: crossAxisCount,
      mainAxisStride: childMainAxisExtent + mainAxisSpacing,
      crossAxisStride: childCrossAxisExtent + crossAxisSpacing,
      childMainAxisExtent: childMainAxisExtent,
      childCrossAxisExtent: childCrossAxisExtent,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(
    SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight oldDelegate,
  ) {
    return oldDelegate.crossAxisCount != crossAxisCount ||
        oldDelegate.mainAxisSpacing != mainAxisSpacing ||
        oldDelegate.crossAxisSpacing != crossAxisSpacing ||
        oldDelegate.height != height;
  }
}
