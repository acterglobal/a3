import 'dart:math';
import 'dart:ui';

import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';

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

extension FfiListFfiStringtoDart on FfiListFfiString {
  List<String> toDart() => asDartStringList(this);
}

double? calcGap(BuildContext context) {
  // ignore: deprecated_member_use
  final double scale = MediaQuery.textScalerOf(context).textScaleFactor;
  if (scale <= 1) return 8;
  return lerpDouble(8, 4, min(scale - 1, 1));
}

/// returns text representation of bytes provided .i.e 1 KB, 1 GB etc
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';

  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
  var i = (log(bytes) / log(1024)).floor();

  // Stay within the range of available suffixes
  i = i >= suffixes.length ? suffixes.length - 1 : i;

  final size = bytes / pow(1024, i);

  // Format number based on size
  if (size >= 100) {
    // No decimal places for large numbers
    return '${size.toStringAsFixed(0)} ${suffixes[i]}';
  } else if (size >= 10) {
    // One decimal place for medium numbers
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  } else {
    // Two decimal places for small numbers
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }
}
