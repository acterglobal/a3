import 'dart:math';
import 'dart:ui';

import 'package:acter/config/constants.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';

final aliasedHttpRegexp = RegExp(
  r'https://matrix.to/#/(?<alias>#.+):(?<server>.+)',
);

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

bool isOnlyEmojis(String text) {
  final emojiRegex = RegExp(
    r'^(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff]|\s)+$',
  );

  return emojiRegex.hasMatch(text.trim());
}

bool isDesktop(BuildContext context) =>
    desktopPlatforms.contains(Theme.of(context).platform);

String jiffyTime(BuildContext context, int timeInterval, {DateTime? toWhen}) {
  final jiffyTime = Jiffy.parseFromMillisecondsSinceEpoch(timeInterval);
  final now = Jiffy.parseFromDateTime(
    toWhen ?? DateTime.now().toUtc(),
  ).startOf(Unit.day);
  if (now.isSame(jiffyTime, unit: Unit.day)) {
    return jiffyTime.jm;
  }

  final yesterday = now.subtract(days: 1);
  if (jiffyTime.isBetween(yesterday, now)) {
    return L10n.of(context).yesterday;
  }

  final week = now.subtract(weeks: 1);
  if (jiffyTime.isBetween(week, now)) {
    return jiffyTime.EEEE;
  }
  return jiffyTime.yMd;
}

String jiffyDateForActvity(BuildContext context, int timeInterval) {
  final activityDate = Jiffy.parseFromMillisecondsSinceEpoch(timeInterval);
  final today = Jiffy.now().startOf(Unit.day);
  final yesterday = today.subtract(days: 1);

  if (activityDate.isSame(today, unit: Unit.day)) {
    return L10n.of(context).today;
  } else if (activityDate.isSame(yesterday, unit: Unit.day)) {
    return L10n.of(context).yesterday;
  }

  return activityDate.yMd;
}

String jiffyDateTimestamp(
  BuildContext context,
  int timeInterval, {
  bool showDay = false,
}) {
  final jiffyTime = Jiffy.parseFromMillisecondsSinceEpoch(timeInterval);
  final now = Jiffy.parseFromDateTime(DateTime.now().toUtc());
  final use24HourFormat = MediaQuery.of(context).alwaysUse24HourFormat;
  final formattedTime = use24HourFormat ? jiffyTime.Hm : jiffyTime.jm;

  if (!showDay) return formattedTime;

  if (now.isSame(jiffyTime, unit: Unit.day)) {
    return formattedTime;
  }

  final week = now.subtract(weeks: 1);
  final year = now.subtract(years: 1);

  if (jiffyTime.isBetween(week, now)) {
    return '${jiffyTime.E} $formattedTime';
  }

  if (jiffyTime.isBefore(week) && jiffyTime.isAfter(year)) {
    return '${jiffyTime.MMMEd} $formattedTime';
  }

  return '${jiffyTime.yMMMEd} $formattedTime';
}

extension TimeOfDayExtension on TimeOfDay {
  /// note: 'hour' is in 24-hour format
  double toDouble() => hour + (minute / 60.0);
}

String taskDueDateFormat(DateTime dateTime) {
  return DateFormat('dd/MM/yyyy').format(dateTime);
}

String formatTimeFromTimestamp(int originServerTs) {
  final originServerDateTime =
      DateTime.fromMillisecondsSinceEpoch(
        originServerTs,
        isUtc: true,
      ).toLocal();
  return DateFormat('hh:mm a').format(originServerDateTime);
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

extension ColorUtils on Color {
  int toInt() {
    final alpha = (a * 255).toInt();
    final red = (r * 255).toInt();
    final green = (g * 255).toInt();
    final blue = (b * 255).toInt();
    // Combine the components into a single int using bit shifting
    return (alpha << 24) | (red << 16) | (green << 8) | blue;
  }
}

/// Comprehensive regex for detecting empty HTML tags and structures
final RegExp emptyHtmlTagsRegex = RegExp(
  r'<br\s*/?>\s*|<p\s*>(\s|&nbsp;|&#160;|<br\s*/?>)*</p>\s*|<div\s*>(\s|&nbsp;|&#160;)*</div>\s*|<span\s*>(\s|&nbsp;|&#160;)*</span>\s*|<h[1-6]\s*>(\s|&nbsp;|&#160;)*</h[1-6]>\s*|<(strong|b|em|i)\s*>(\s|&nbsp;|&#160;)*</(strong|b|em|i)>\s*|<(ul|ol|li)\s*>(\s|&nbsp;|&#160;)*</(ul|ol|li)>\s*',
  multiLine: true,
  caseSensitive: false,
);

/// Check if HTML content contains only empty tags or whitespace
bool isEmptyHtmlContent(String html) {
  if (html.trim().isEmpty) return true;
  
  // Remove all empty tags and structures
  String cleanedHtml = html
      .replaceAll(emptyHtmlTagsRegex, '')
      .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
      .trim();
  
  return cleanedHtml.isEmpty;
}

/// html requires to have some kind of structure even when document is empty, so check for that
bool hasValidEditorContent({required String plainText, required String html}) {
  if (plainText.trim().isEmpty && html.trim().isEmpty) return false;

  // Use the comprehensive empty HTML check
  return !isEmptyHtmlContent(html);
}

String formatChatDayDividerDateString(BuildContext context, String dateString) {
  try {
    final lang = L10n.of(context);

    // Parse the date string using Jiffy
    final messageDate = Jiffy.parse(dateString).startOf(Unit.day);
    final today = Jiffy.now().startOf(Unit.day);
    final yesterday = today.subtract(days: 1);

    if (messageDate.isSame(today, unit: Unit.day)) {
      return lang.today;
    } else if (messageDate.isSame(yesterday, unit: Unit.day)) {
      return lang.yesterday;
    } else {
      // Check if it's the same year
      if (messageDate.isSame(today, unit: Unit.year)) {
        // Same year: show day name, date and month (e.g., "Fri, May 17")
        return messageDate.format(pattern: 'EEE, d MMM');
      } else {
        // Different year: show month, date and year (e.g., "May 17, 2025")
        return messageDate.format(pattern: 'd MMM, y');
      }
    }
  } catch (e) {
    // If parsing fails, return the original string
    return dateString;
  }
}
