import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:logging/logging.dart';

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

bool isValidUrl(String url) {
// Regular expression to validate URLs
  final RegExp urlPattern = RegExp(
    r"^([a-zA-Z][a-zA-Z\d+\-.]*):\/\/([\w\-])+\.{1}([a-zA-Z]{2,63})([\w\-\._~:/?#[\]@!\$&'()*+,;=.]+)?$",
    caseSensitive: false,
  );
  return urlPattern.hasMatch(url);
}

/// Get provider right from the context no matter where we are
extension ProviderScopeContext on BuildContext {
  // Custom call a provider for reading method only
  // It will be helpful for us for calling the read function
  // without Consumer,ConsumerWidget or ConsumerStatefulWidget
  // Incase if you face any issue using this then please wrap your widget
  // with consumer and then call your provider

  T read<T>(ProviderListenable<T> provider) {
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

extension ActerContextUtils on BuildContext {
  bool get isLargeScreen =>
      MediaQuery.of(this).size.width >= largeScreenBreakPoint;
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
  return '${DateFormat.jm().format(start)} - ${DateFormat.jm().format(end)}';
}

String getMonthFromDate(UtcDateTime utcDateTime) {
  final localDateTime = toDartDatetime(utcDateTime).toLocal();
  final month = DateFormat.MMM().format(localDateTime);
  return month;
}

String getDayFromDate(UtcDateTime utcDateTime) {
  final localDateTime = toDartDatetime(utcDateTime).toLocal();
  final day = DateFormat.d().format(localDateTime);
  return day;
}

String getTimeFromDate(BuildContext context, UtcDateTime utcDateTime) {
  final localDateTime = toDartDatetime(utcDateTime).toLocal();
  return DateFormat.jm().format(localDateTime);
}

String jiffyTime(BuildContext context, int timeInterval) {
  final jiffyTime = Jiffy.parseFromMillisecondsSinceEpoch(timeInterval);
  final now = Jiffy.now().startOf(Unit.day);
  if (now.isSame(jiffyTime, unit: Unit.day)) {
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

String taskDueDateFormat(DateTime dateTime) {
  return DateFormat('dd/MM/yyyy').format(dateTime);
}

String getHumanReadableFileSize(int bytes) {
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
  var i = (log(bytes) / log(1024)).floor();
  return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
}

String documentTypeFromFileExtension(String fileExtension) {
  return switch (fileExtension) {
    '.png' || '.jpg' || '.jpeg' => 'Image',
    '.mov' || '.mp4' => 'Video',
    '.mp3' || '.wav' => 'Audio',
    '.pdf' => 'PDF',
    '.txt' => 'Text File',
    _ => '',
  };
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

T getRandomElement<T>(List<T> list) {
  final i = Random().nextInt(list.length);
  return list[i];
}

String simplifyBody(String formattedBody) {
  // strip out parent msg from reply msg
  RegExp re = RegExp(r'^<mx-reply>[\s\S]+</mx-reply>');
  return formattedBody.replaceAll(re, '');
}

///helper function to convert list ffiString object to DartString.
List<String> asDartStringList(FfiListFfiString data) {
  if (data.isEmpty) return [];
  return data.toList().map((e) => e.toDartString()).toList();
}

double? calcGap(BuildContext context) {
  // ignore: deprecated_member_use
  final double scale = MediaQuery.textScalerOf(context).textScaleFactor;
  if (scale <= 1) return 8;
  return lerpDouble(8, 4, min(scale - 1, 1));
}

// helper fn to mimic Option::map() in rust
// it is used to remove bang operator about nullable variable
extension Let<T> on T? {
  R? let<R>(R? Function(T) op) {
    final T? value = this;
    return value == null ? null : op(value);
  }

  // it supports async callback too unlike `extension_nullable`
  Future<R?> letAsync<R>(R? Function(T) op) async {
    final T? value = this;
    return value == null ? null : op(value);
  }
}
