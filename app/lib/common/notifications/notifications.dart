import 'dart:io';

import 'package:acter/common/notifications/models.dart';
import 'package:acter/router/router.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plain_notification_token/plain_notification_token.dart';
import 'package:device_info_plus/device_info_plus.dart';

final plainNotificationToken = PlainNotificationToken();
final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

const bool isProduction = bool.fromEnvironment('dart.vm.product');

const appIdPrefix = String.fromEnvironment(
  'PUSH_APP_PREFIX',
  defaultValue: 'global.acter.a3',
);

const appName = String.fromEnvironment(
  'PUSH_APP_NAME',
  defaultValue: 'Acter',
);

const pushServerUrl = String.fromEnvironment(
  'PUSH_URL',
  defaultValue: 'https://localhost:8228/_matrix/push/v1/notify',
);

class NotificationController {
  /// Use this method to detect when a new notification or a schedule is created
  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    // Your code goes here
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    // Your code goes here
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    // Your code goes here
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    // Your code goes here

    // Navigate into pages, avoiding to open the notification details page over another details page already opened
    rootNavKey.currentState?.pushNamed('/settings', arguments: receivedAction);
  }
}

Future<void> initializeNotifications() async {
  AwesomeNotifications().initialize(
    // set the icon to null if you want to use the default app icon
    null,
    // 'resource://drawable/res_app_icon',
    [
      NotificationChannel(
        channelGroupKey: 'basic_channel_group',
        channelKey: 'basic_channel',
        channelName: 'Basic notifications',
        channelDescription: 'Notification channel for basic tests',
        defaultColor: const Color(0xFF9D50DD),
        ledColor: Colors.white,
      ),
    ],
    // Channel groups are only visual and are not required
    channelGroups: [
      NotificationChannelGroup(
        channelGroupKey: 'basic_channel_group',
        channelGroupName: 'Basic group',
      ),
    ],
    debug: true,
  );
}

Future<bool> setupPushNotifications(
  Client client, {
  forced = false,
}) async {
  if (!(Platform.isAndroid || Platform.isIOS || Platform.isLinux)) {
    // we are only supporting this on a limited set of platforms at the moment.
    return false;
  }

  final isAllowed = await AwesomeNotifications().isNotificationAllowed();
  final userId = client.userId().toString();
  final SharedPreferences preferences = await sharedPrefs();
  final prefKey = '$userId.rejected_notifications';
  if (!isAllowed) {
    // check whether we were already rejected and thus shouldn't ask again
    if (!forced && (preferences.getBool(prefKey) ?? false)) {
      // we need to be forced to continue
      return false;
    }
    // TASK: show some extra dialog here?
    final requested =
        await AwesomeNotifications().requestPermissionToSendNotifications();
    if (!requested) {
      // we were bluntly rejected, save and don't them bother again:
      preferences.setBool(prefKey, false);
      return false;
    }
  }

  if (Platform.isLinux) {
    // that's it for us on here.
    return true;
  }

  final String? token = await plainNotificationToken.getToken();
  if (token == null) {
    return false;
  }

  late String name;
  late String appId;
  if (Platform.isIOS) {
    final iOsInfo = await deviceInfo.iosInfo;
    name = iOsInfo.name;
    appId = '$appIdPrefix.android';
  } else if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    name = androidInfo.host; // FIXME: confirm this is what we actually want?!?
    if (isProduction) {
      appId = '$appIdPrefix.ios';
    } else {
      appId = '$appIdPrefix.ios.dev';
    }
  }

  await client.addPusher(appId, token, name, appName, pushServerUrl, null);

  debugPrint(
    ' ---- notification pusher sent: $appName ($appId) on $name ($token) to $pushServerUrl',
  );

  return true;
}

Future<void> setupNotificationsListeners() async {
  // Only after at least the action method is set, the notification events are delivered
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: NotificationController.onActionReceivedMethod,
    onNotificationCreatedMethod:
        NotificationController.onNotificationCreatedMethod,
    onNotificationDisplayedMethod:
        NotificationController.onNotificationDisplayedMethod,
    onDismissActionReceivedMethod:
        NotificationController.onDismissActionReceivedMethod,
  );
}

Future<void> notify(NotificationBrief brief) async {
  AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 10,
      channelKey: 'basic_channel',
      actionType: ActionType.Default,
      category: NotificationCategory.Message,
      title: brief.title,
    ),
  );
}
