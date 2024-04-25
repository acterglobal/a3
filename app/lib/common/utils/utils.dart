// ignore_for_file: unnecessary_null_comparison

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

final _log = Logger('a3::common::util');

final aliasedHttpRegexp =
    RegExp(r'https://matrix.to/#/(?<alias>#.+):(?<server>.+)');

final idAliasRegexp = RegExp(
  r'matrix:r/(?<id>[^?]+)(\?via=(?<server_name>[^&]+))?(&via=(?<server_name2>[^&]+))?(&via=(?<server_name3>[^&]+))?',
);

final idHttpRegexp = RegExp(
  r'https://matrix.to/#/!(?<id>[^?]+)(\?via=(?<server_name>[^&]+))?(&via=(?<server_name2>[^&]+))?(&via=(?<server_name3>[^&]+))?',
);

final idMatrixRegexp = RegExp(
  r'matrix:roomid/(?<id>[^?]+)(\?via=(?<server_name>[^&]+))?(&via=(?<server_name2>[^&]+))?(&via=(?<server_name3>[^&]+))?',
);

/// Get provider right from the context no matter where we are
extension Context on BuildContext {
  // Custom call a provider for reading method only
  // It will be helpful for us for calling the read function
  // without Consumer,ConsumerWidget or ConsumerStatefulWidget
  // Incase if you face any issue using this then please wrap your widget
  // with consumer and then call your provider

  T read<T>(ProviderBase<T> provider) {
    return ProviderScope.containerOf(this, listen: false).read(provider);
  }
}

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

const largeScreenBreakPoint = 770;

bool isLargeScreen(BuildContext context) {
  return MediaQuery.of(context).size.width >= largeScreenBreakPoint;
}

DateTime kFirstDay = DateTime.utc(2010, 10, 16);
DateTime kLastDay = DateTime.utc(2050, 12, 31);

List<DateTime> daysInRange(DateTime first, DateTime last) {
  final dayCount = last.difference(first).inDays + 1;
  return List.generate(
    dayCount,
    (index) => DateTime.utc(first.year, first.month, first.day + index),
  );
}

String formatDate(CalendarEvent e) {
  final start = toDartDatetime(e.utcStart()).toLocal();
  final end = toDartDatetime(e.utcEnd()).toLocal();
  final startFmt = DateFormat.yMMMd().format(start);
  if (start.difference(end).inDays == 0) {
    return startFmt;
  } else {
    final endFmt = DateFormat.yMMMd().format(end);
    return '$startFmt - $endFmt';
  }
}

String formatTime(CalendarEvent e) {
  final start = toDartDatetime(e.utcStart()).toLocal();
  final end = toDartDatetime(e.utcEnd()).toLocal();
  return '${Jiffy.parseFromDateTime(start).jm} - ${Jiffy.parseFromDateTime(end).jm}';
}

String getMonthFromDate(UtcDateTime utcDateTime) {
  final localDateTime = toDartDatetime(utcDateTime).toLocal();
  final month = DateFormat('MMM').format(localDateTime);
  return month;
}

String getDayFromDate(UtcDateTime utcDateTime) {
  final localDateTime = toDartDatetime(utcDateTime).toLocal();
  final day = DateFormat('dd').format(localDateTime);
  return day;
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

extension TimeOfDayExtension on TimeOfDay {
  /// note: 'hour' is in 24-hour format
  double toDouble() => hour + (minute / 60.0);
}

String eventDateFormat(DateTime dateTime) {
  return DateFormat('MMM dd, yyyy').format(dateTime);
}

Future<bool> openLink(String target, BuildContext context) async {
  final Uri? url = Uri.tryParse(target);
  if (url == null || !url.hasAuthority) {
    _log.info('Opening internally: $url');
    // not a valid URL, try local routing
    await context.push(target);
    return true;
  } else {
    _log.info('Opening external URL: $url');
    return await launchUrl(url);
  }
}

Future<void> mailTo({required String toAddress, String? subject}) async {
  final Uri emailLaunchUri =
      Uri(scheme: 'mailto', path: toAddress, query: subject);
  await launchUrl(emailLaunchUri);
}

String randomString() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}

T getRandomElement<T>(List<T> list) {
  final i = Random().nextInt(list.length);
  return list[i];
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
    '${a.toRadixString(16)}${r.toRadixString(16)}${g.toRadixString(16)}${b.toRadixString(16)}',
    radix: 16,
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
  String toRfc3339() {
    return toUtc().toIso8601String();
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
        String? seg = m2.group(1);
        if (seg == null) {
          return '';
        }
        int charCode = int.parse(seg, radix: 16);
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
enum RoomVisibility { Public, Private, SpaceVisible }

enum LabsFeature {
  // apps in general
  tasks,
  notes,
  cobudget,
  polls,
  discussions,
  comments,

  // not a lab anymore but needs to stay for backwards compat
  events,
  pins,

  // searchOptions
  encryptionBackup,
  showNotifications, // FIXME: old name for desktop notifications
  mobilePushNotifications;

  static List<LabsFeature> get defaults => [
        LabsFeature.comments,
        LabsFeature.mobilePushNotifications,
      ];
}

// typedef ChatWithProfileData = ({Convo chat, ProfileData profile});
// typedef SpaceWithProfileData = ({Space space, ProfileData profile});
// typedef MemberInfo = ({String userId, String? roomId});
// typedef ChatMessageInfo = ({String messageId, String roomId});
// typedef AttachmentInfo = ({AttachmentType type, File file});
