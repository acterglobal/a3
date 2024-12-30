library;

import 'dart:async';
import 'dart:io';

import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/local.dart';
import 'package:acter_notifify/ntfy.dart';
import 'package:acter_notifify/push.dart';
import 'package:acter_notifify/util.dart';
import 'package:acter_notifify/platform/windows.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final _log = Logger('a3::notifify::acter');

/// Function to call when a notification has been tapped by the user
typedef HandleMessageTap = FutureOr<bool> Function(Map<String?, Object?> data);

/// Function called at starting to process any notification to check whether
/// we should continue or not bother the user. Just a user based switch
typedef IsEnabledCheck = FutureOr<bool> Function();

/// Given the target url of the notification, should this notification be shown
/// or just be ignored. Useful to avoid showing push notification if the user
/// is on that same screen
typedef ShouldShowCheck = FutureOr<bool> Function(String url);

/// When we get a new token, we inform all clients about this. We call this callback
/// to get a list of currently activated clients.
typedef CurrentClientsGen = FutureOr<List<Client>> Function();

/// Initialize Notification support
Future<String?> initializeNotifify({
  required HandleMessageTap handleMessageTap,
  required String appName,
  required String appIdPrefix,
  required String pushServer,
  required String ntfyServer,
  String? winApplicationId,
  FirebaseOptions? androidFirebaseOptions,
  IsEnabledCheck? isEnabledCheck,
  ShouldShowCheck? shouldShowCheck,
  CurrentClientsGen? currentClientsGen,
}) async {
  String? initialUrl;
  if (Platform.isFuchsia) {
    // not supported yet;
    return null;
  }
  if (Platform.isAndroid) {
    await Firebase.initializeApp(
      options: androidFirebaseOptions,
    );
  }

  if (Platform.isWindows) {
    initializeWindowsNotifications(
      applicationId: winApplicationId,
      handleMessageTap: handleMessageTap,
    );
  } else {
    initialUrl =
        await initializeLocalNotifications(handleMessageTap: handleMessageTap);
  }

  if (usePush && pushServer.isNotEmpty) {
    await initializePush(
      handleMessageTap: handleMessageTap,
      shouldShowCheck: (a) async {
        /// FIXME: to ensure we see failures after, this is being ignored for now
        try {
          if (shouldShowCheck != null) {
            final res = await shouldShowCheck(a);
            _log.info('Should show $a: $res');
          }
        } catch (e, s) {
          _log.severe('Checking whether $a should be shown failed', e, s);
        }
        return true;
      },
      isEnabledCheck: isEnabledCheck,
      currentClientsGen: currentClientsGen,
      appIdPrefix: appIdPrefix,
      appName: appName,
      pushServerUrl: 'https://$pushServer/_matrix/push/v1/notify',
    );
  }
  if (!usePush && ntfyServer.isNotEmpty && currentClientsGen != null) {
    final clients = await currentClientsGen();
    for (final client in clients) {
      try {
        await setupNtfyNotificationsForDevice(
          client,
          appIdPrefix: appIdPrefix,
          appName: appName,
          ntfyServer: ntfyServer,
        );
      } catch (error, stack) {
        final deviceId = client.deviceId().toString();
        Sentry.captureException(error, stackTrace: stack);
        _log.severe('Failed to setup ntfy for $deviceId', error, stack);
      }
    }
  }
  return initialUrl;
}

/// Return false if the user declined the request to
/// allow notification, null if no token was found and
/// true if the token was successfully committed along
/// side the pushserver
Future<bool?> setupNotificationsForDevice(
  Client client, {
  required String appName,
  required String appIdPrefix,
  required String pushServer,
  required String ntfyServer,
}) async {
  if (Platform.isFuchsia) {
    // not supported yet;
    return null;
  }
  if (usePush && pushServer.isNotEmpty) {
    return await setupPushNotificationsForDevice(
      client,
      appIdPrefix: appIdPrefix,
      appName: appName,
      pushServerUrl: 'https://$pushServer/_matrix/push/v1/notify',
    );
  }
  if (!usePush && ntfyServer.isNotEmpty) {
    return await setupNtfyNotificationsForDevice(
      client,
      appIdPrefix: appIdPrefix,
      appName: appName,
      ntfyServer: ntfyServer,
    );
  }
  return null;
}
