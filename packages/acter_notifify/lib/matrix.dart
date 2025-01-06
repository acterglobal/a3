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
  final deviceId = message['device_id'] as String?;

  final mayBeRoomId = message['room_id'];
  final mayBeEventId = message['event_id'];

  if (mayBeEventId == null || mayBeRoomId == null || deviceId == null) {
    throw 'Received unsupported notification without deviceId, eventId and/or room Id. Skipping. message: $message';
  }
  final roomId = mayBeRoomId as String;
  final eventId = mayBeEventId as String;
  _log.info('Received msg $roomId: $eventId');
  final instance = await ActerSdk.instance;
  return await instance.getNotificationFor(deviceId, roomId, eventId);
}

Future<bool> handleMatrixMessage(
  Map<String?, Object?> message, {
  bool background = false,
  ShouldShowCheck? shouldShowCheck,
}) async {
  late NotificationItem notification;
  try {
    notification = await _getNotificationItem(message);
  } catch (error, stack) {
    Sentry.captureException(error, stackTrace: stack);
    Sentry.captureMessage(
      level: SentryLevel.error,
      'getting notification from message failed: %s - %s',
      params: [error, message],
    );
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

(String, String?) genTitleAndBody(NotificationItem notification) =>
    switch (notification.pushStyle()) {
      "comment" => _titleAndBodyForComment(notification),
      "reaction" => _titleAndBodyForReaction(notification),
      _ => _fallbackTitleAndBody(notification),
    };

(String, String?) _fallbackTitleAndBody(NotificationItem notification) =>
    (notification.title(), notification.body()?.body());

String _parentPart(NotificationItemParent parent) {
  final emoji = parent.emoji();
  final title = switch (parent.objectTypeStr()) {
    'news' => "boost",
    _ => parent.title(),
  };
  return "$emoji $title";
}

(String, String?) _titleAndBodyForComment(NotificationItem notification) {
  final parent = notification.parent();
  String title = "💬 Comment";
  if (parent != null) {
    final parentInfo = _parentPart(parent);
    title = "$title on $parentInfo";
  }

  final comment = notification.body()?.body();
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();

  return (title, "$username: $comment");
}

(String, String?) _titleAndBodyForReaction(NotificationItem notification) {
  final parent = notification.parent();
  final reaction = notification.reactionKey() ?? '❤️';
  String title = '"$reaction"';
  if (parent != null) {
    final parentInfo = _parentPart(parent);
    title = "$title to $parentInfo";
  }

  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();

  return (title, username);
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
