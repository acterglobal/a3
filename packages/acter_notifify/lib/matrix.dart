import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:acter_notifify/acter_notifify.dart';
import 'package:acter_notifify/platform/android.dart';
import 'package:acter_notifify/platform/darwin.dart';
import 'package:acter_notifify/local.dart';
import 'package:acter_notifify/platform/linux.dart';
import 'package:acter_notifify/util.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/platform/windows.dart';
import 'package:convert/convert.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final _log = Logger('a3::notifify::matrix');

int id = 0;

const bool isProduction = bool.fromEnvironment('dart.vm.product');

Future<NotificationItem> _getNotificationItem(
  Map<String?, Object?> message,
) async {
  final deviceId = message['device_id'] as String;

  final roomId = message['room_id'] as String;
  final eventId = message['event_id'] as String;
  _log.info('Received msg $roomId: $eventId');
  final instance = await ActerSdk.instance;
  return await instance.getNotificationFor(deviceId, roomId, eventId);
}

Future<bool> _handleCountsUpdate(
  Map<String?, Object?> message,
) async {
  final msg = message['count'] as Map? ?? message;
  final totalCounts =
      ((msg['unread'] as int?) ?? 0) + ((msg['missed_calls'] as int?) ?? 0);
  await updateBadgeCount(totalCounts);
  return false;
}

Future<bool> handleMatrixMessage(
  Map<String?, Object?> message, {
  bool background = false,
  ShouldShowCheck? shouldShowCheck,
}) async {
  late NotificationItem notification;
  if (message["event_id"] == null ||
      message['room_id'] == null ||
      message['device_id'] == null) {
    // this message doesn't actually contain any regular information
    // just badge counter updates.
    return _handleCountsUpdate(message);
  }

  try {
    notification = await _getNotificationItem(message);
  } catch (error, stack) {
    Sentry.captureException(error, stackTrace: stack);
    Sentry.captureMessage(
      level: SentryLevel.error,
      'getting notification from message failed: %s - %s',
      params: [error, message],
    );
    return false;
  }
  _log.info('got a notification');

  if (shouldShowCheck != null &&
      !await shouldShowCheck(notification.targetUrl())) {
    _log.info(
      'Ignoring notification: user is looking at this screen already',
    );
    return false;
  }
  try {
    await _showNotification(notification);
    return true;
  } catch (e, s) {
    _log.severe('Showing Notification failed: $message', e, s);
    Sentry.captureException(e, stackTrace: s);
    Sentry.captureMessage(
      level: SentryLevel.error,
      'Showing Notification failed: %s - %s',
      params: [e, message],
    );
  }
  return false;
}

Future<void> _showNotification(NotificationItem notification) async {
  if (Platform.isAndroid) {
    return await showNotificationOnAndroid(notification);
  } else if (Platform.isWindows) {
    return await showWindowsNotification(notification);
  }

  // fallback for linux & macos
  final (title, body) = genTitleAndBody(notification);
  DarwinNotificationDetails? darwinDetails;
  LinuxNotificationDetails? linuxDetails;

  if (Platform.isIOS || Platform.isMacOS) {
    darwinDetails = await genDarwinDetails(notification);
  } else if (Platform.isLinux) {
    linuxDetails = await genLinuxDetails(notification);
  }

  await flutterLocalNotificationsPlugin.show(
    id++,
    title,
    body,
    NotificationDetails(
      macOS: darwinDetails,
      iOS: darwinDetails,
      linux: linuxDetails,
    ),
    payload: notification.targetUrl(),
  );
}

Future<bool> addToken(
  Client client,
  String token, {
  required String appName,
  required String appIdPrefix,
  required String pushServerUrl,
}) async {
  final String name = await deviceName();
  late String appId;
  if (Platform.isIOS) {
    // sygnal expects token as a base64 encoded string, but we have a HEX from the plugin
    token = base64.encode(hex.decode(token));
    if (isProduction) {
      appId = '$appIdPrefix.ios';
    } else {
      appId = '$appIdPrefix.ios.dev';
    }
  } else {
    appId = '$appIdPrefix.${Platform.operatingSystem}';
  }

  await client.addPusher(
    appId,
    token,
    name,
    appName,
    pushServerUrl,
    Platform.isIOS,
    null,
  );

  _log.info(
    'notification pusher set: $appName ($appId) on $name ($token) to $pushServerUrl',
  );

  await client.installDefaultActerPushRules();

  _log.info('default push rules submitted');
  return true;
}
