import 'dart:async';
import 'dart:math';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
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

final urlValidatorRegexp = RegExp(
  r'^[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b[-a-zA-Z0-9()@:%_+.~#?&/=]*$',
);

/// Get provider right from the context no matter where we are
extension Context on BuildContext {
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

Future<void> shareTextToWhatsApp(
  BuildContext context, {
  required String text,
}) async {
  final url = 'whatsapp://send?text=$text';
  final encodedUri = Uri.parse(url);
  if (await canLaunchUrl(encodedUri)) {
    await launchUrl(encodedUri);
  } else {
    _log.warning('WhatsApp not available');
    if (!context.mounted) return;
    EasyLoading.showError(
      L10n.of(context).appUnavailable,
      duration: const Duration(seconds: 3),
    );
  }
}

Future<void> mailTo({required String toAddress, String? subject}) async {
  final emailLaunchUri = Uri(
    scheme: 'mailto',
    path: toAddress,
    query: subject,
  );
  await launchUrl(emailLaunchUri);
}

Future<void> openAvatar(
  BuildContext context,
  WidgetRef ref,
  String roomId,
) async {
  final membership = await ref.read(roomMembershipProvider(roomId).future);
  final canUpdateAvatar = membership?.canString('CanUpdateAvatar') == true;
  final avatarInfo = ref.read(roomAvatarInfoProvider(roomId));

  if (avatarInfo.avatar != null) {
    if (context.mounted) {
      //Open avatar in full screen if avatar data available
      context.pushNamed(
        Routes.fullScreenAvatar.name,
        queryParameters: {'roomId': roomId},
      );
    }
  } else {
    if (canUpdateAvatar && context.mounted) {
      //Change avatar if avatar is null and have relevant permission
      uploadAvatar(ref, context, roomId);
    }
  }
}

Future<void> uploadAvatar(
  WidgetRef ref,
  BuildContext context,
  String roomId,
) async {
  final room = await ref.read(maybeRoomProvider(roomId).future);
  if (room == null || !context.mounted) return;
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.image,
  );
  if (result == null || result.files.isEmpty) return;
  try {
    if (!context.mounted) return;
    EasyLoading.show(status: L10n.of(context).avatarUploading);
    final filePath = result.files.first.path;
    if (filePath != null) await room.uploadAvatar(filePath);
    // close loading
    EasyLoading.dismiss();
  } catch (e, s) {
    _log.severe('Failed to upload avatar', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showError(
      L10n.of(context).failedToUploadAvatar(e),
      duration: const Duration(seconds: 3),
    );
  }
}

T getRandomElement<T>(List<T> list) {
  final i = Random().nextInt(list.length);
  return list[i];
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

String simplifyBody(String formattedBody) {
  // strip out parent msg from reply msg
  RegExp re = RegExp(r'^<mx-reply>[\s\S]+</mx-reply>');
  return formattedBody.replaceAll(re, '');
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
  notes,
  cobudget,
  polls,
  discussions,

  // specific features
  chatUnread,

  // system features
  deviceCalendarSync,
  encryptionBackup,

  // candidates for always on
  comments,
  mobilePushNotifications,

  // -- not a lab anymore but needs to stay for backwards compat
  tasks,
  events,
  pins,
  showNotifications; // old name for desktop notifications

  static List<LabsFeature> get defaults =>
      isDevBuild || isNightly ? nightlyDefaults : releaseDefaults;

  static List<LabsFeature> get releaseDefaults => [
        LabsFeature.mobilePushNotifications,
      ];

  static List<LabsFeature> get nightlyDefaults => [
        LabsFeature.encryptionBackup,
        LabsFeature.deviceCalendarSync,
        LabsFeature.mobilePushNotifications,
      ];
}

// typedef ChatWithProfileData = ({Convo chat, ProfileData profile});
// typedef SpaceWithProfileData = ({Space space, ProfileData profile});
// typedef MemberInfo = ({String userId, String? roomId});
// typedef ChatMessageInfo = ({String messageId, String roomId});
// typedef AttachmentInfo = ({AttachmentType type, File file});
