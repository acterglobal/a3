import 'dart:io';

import 'package:acter_notifify/platform/android.dart';
import 'package:acter_notifify/local.dart';
import 'package:acter_notifify/platform/windows.dart';
import 'package:device_info_plus/device_info_plus.dart';

final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

final useLocal = Platform.isAndroid ||
    Platform.isIOS ||
    Platform.isMacOS ||
    Platform.isLinux; // || Platform.isMacOS;

final usePush = Platform.isAndroid || Platform.isIOS;

Future<void> removeNotificationsForRoom(String roomId) async {
  await cancelInThread(roomId);
  if (Platform.isAndroid) {
    androidClearNotificationsCache(roomId);
  } else if (Platform.isWindows) {
    windowsClearNotificationsCache(roomId);
  }
}

Future<void> cancelInThread(String threadId) async {
  if (!useLocal) {
    return; // nothing for us to do here.
  }

  final toCancel =
      (await flutterLocalNotificationsPlugin.getActiveNotifications())
          .where(
            (element) => element.groupKey == threadId,
          )
          .map(
            (e) => e.id,
          )
          .toList();

  for (final id in toCancel) {
    if (id != null) {
      await flutterLocalNotificationsPlugin.cancel(id);
    }
  }
}

Future<String> deviceName() async {
  if (Platform.isIOS) {
    final iOsInfo = await deviceInfo.iosInfo;
    return iOsInfo.name;
  } else if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.device;
  } else if (Platform.isMacOS) {
    final info = await deviceInfo.macOsInfo;
    return info.computerName;
  } else if (Platform.isLinux) {
    final info = await deviceInfo.linuxInfo;
    return info.prettyName;
  } else if (Platform.isWindows) {
    final info = await deviceInfo.windowsInfo;
    return info.computerName;
  } else {
    return '(unknown)';
  }
}
