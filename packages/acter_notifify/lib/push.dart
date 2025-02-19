import 'dart:async';
import 'dart:io';

import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/acter_notifify.dart';
import 'package:acter_notifify/matrix.dart';
import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:push/push.dart';

final _log = Logger('a3::notifify::push');

Future<void> initializePush({
  required HandleMessageTap handleMessageTap,
  IsEnabledCheck? isEnabledCheck,
  ShouldShowCheck? shouldShowCheck,
  CurrentClientsGen? currentClientsGen,
  required String appName,
  required String appIdPrefix,
  required String pushServerUrl,
}) async {
  try {
    // Handle notification launching app from terminated state

    //ON ANDROID: PUSH NOTIFICATION TAP IS MANAGED BY LOCAL PUSH NOTIFICATION TAP EVENT
    if (!Platform.isAndroid) {
      Push.instance.notificationTapWhichLaunchedAppFromTerminated.then((data) {
        if (data != null) {
          _log.info('Notification tap launched app from terminated state:\n'
              'RemoteMessage: $data \n');
          handleMessageTap(data);
        }
      });

      // Handle notification taps
      Push.instance.onNotificationTap.listen((data) {
        handleMessageTap(data);
      });
    }

    // Handle push notifications
    Push.instance.addOnMessage((message) async {
      if (isEnabledCheck != null && !await isEnabledCheck()) {
        return;
      }
      await _handlePushMessage(
        message,
        background: false,
        shouldShowCheck: shouldShowCheck,
      );
    });

    // Handle push notifications on background - in iOS we are doing that in
    // the other instance.
    if (!Platform.isIOS) {
      Push.instance.addOnBackgroundMessage((message) async {
        if (isEnabledCheck != null && !await isEnabledCheck()) {
          return;
        }
        await _handlePushMessage(
          message,
          background: true,
          shouldShowCheck: shouldShowCheck,
        );
      });
    }

    // To be informed that the device's token has been updated by the operating system
    // You should update your servers with this token
    Push.instance.onNewToken.listen((token) async {
      // FIXME: how to identify which clients are connected to this?
      _log.info('Just got a new FCM registration token: $token');
      final clients =
      currentClientsGen == null ? [] : await currentClientsGen();
      for (final client in clients) {
        final deviceId = client.deviceId().toString();
        try {
          await addToken(client, token,
              appIdPrefix: appIdPrefix,
              appName: appName,
              pushServerUrl: pushServerUrl);
        } catch (error, st) {
          _log.severe('Setting token for $deviceId failed', error, st);
          Sentry.captureException(error, stackTrace: st);
        }
      }
    });
  } catch (e, s) {
    // this fails on hot-reload and in integration tests... if so, ignore for now
    _log.severe('Push initialization error', e, s);
    Sentry.captureException(e, stackTrace: s);
  }
}

Future<bool> _handlePushMessage(RemoteMessage message, {
  bool background = false,
  ShouldShowCheck? shouldShowCheck,
}) async {
  if (message.data == null) {
    _log.info('non-matrix push: $message');
    return false;
  }
  return await handleMatrixMessage(message.data!,
      background: background, shouldShowCheck: shouldShowCheck);
}

Future<bool?> setupPushNotificationsForDevice(Client client, {
  required String appName,
  required String appIdPrefix,
  required String pushServerUrl,
}) async {
  // this show some extra dialog here on devices where necessary
  final requested = await Push.instance.requestPermission(
    badge: true,
    alert: true, // we request loud notifications now.
  );
  if (!requested) {
    // we were bluntly rejected, save and don’t them bother again:
    return false;
  }

  // let’s get the token
  final token = await Push.instance.token;

  if (token == null) {
    _log.info('No token given');
    return null;
  }

  return await addToken(client, token,
      appIdPrefix: appIdPrefix, appName: appName, pushServerUrl: pushServerUrl);
}
