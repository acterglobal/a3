import 'dart:io';
import 'dart:convert';

import 'package:convert/convert.dart';

import 'package:acter/common/notifications/models.dart';
import 'package:acter/router/router.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plain_notification_token/plain_notification_token.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:firebase_core/firebase_core.dart';

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

const pushServer = String.fromEnvironment(
  'PUSH_SERVER',
  defaultValue: '',
);

class NotificationController {
  /// Use this method to detect when a new notification or a schedule is created
  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    // Your code goes here
    debugPrint("received notification: ${receivedNotification.payload}");
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    // Your code goes here
    debugPrint("displayed notification: ${receivedNotification.payload}");
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    // Your code goes here
    debugPrint("dismissed notification: $receivedAction");
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    // Your code goes here
    debugPrint("called notification: $receivedAction");

    // Navigate into pages, avoiding to open the notification details page over another details page already opened
    rootNavKey.currentState?.pushNamed('/settings', arguments: receivedAction);
  }

  static Future<void> initializeRemoteNotifications({
    required bool debug
  }) async {
    await Firebase.initializeApp();
    await AwesomeNotificationsFcm().initialize(
        onFcmSilentDataHandle: NotificationController.mySilentDataHandle,
        onFcmTokenHandle: NotificationController.myFcmTokenHandle,
        onNativeTokenHandle: NotificationController.myNativeTokenHandle,
        // This license key is necessary only to remove the watermark for
        // push notifications in release mode. To know more about it, please
        // visit http://awesome-notifications.carda.me#prices
        // licenseKey: null,
        debug: debug);
  }

  ///  *********************************************
  ///     REMOTE NOTIFICATION EVENTS
  ///  *********************************************

  /// Use this method to execute on background when a silent data arrives
  /// (even while terminated)
  @pragma("vm:entry-point")
  static Future<void> mySilentDataHandle(FcmSilentData silentData) async {
    print('"SilentData": ${silentData.toString()}');

    if (silentData.createdLifeCycle != NotificationLifeCycle.Foreground) {
      print("bg");
    } else {
      print("FOREGROUND");
    }

    print("starting long task");
    await Future.delayed(Duration(seconds: 4));
    print("long task done");
  }

  /// Use this method to detect when a new fcm token is received
  @pragma("vm:entry-point")
  static Future<void> myFcmTokenHandle(String token) async {
    debugPrint('FCM Token:"$token"');
  }

  /// Use this method to detect when a new native token is received
  @pragma("vm:entry-point")
  static Future<void> myNativeTokenHandle(String token) async {
    debugPrint('Native Token:"$token"');
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
  if (pushServer.isEmpty) {
    // no server given. Ignoring
    return false;
  }
  const pushServerUrl = 'https://$pushServer/_matrix/push/v1/notify';
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

  String? token = await plainNotificationToken.getToken();
  if (token == null) {
    return false;
  }

  late String name;
  late String appId;
  if (Platform.isIOS) {
    // FIXME sygnal expects token as a base64 encoded string, but we have a HEX from the plugin
    token = base64.encode(hex.decode(token));

    final iOsInfo = await deviceInfo.iosInfo;
    name = iOsInfo.name;
    if (isProduction) {
      appId = '$appIdPrefix.ios';
    } else {
      appId = '$appIdPrefix.ios.dev';
    }
  } else if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    name =
        androidInfo.device; // FIXME: confirm this is what we actually want?!?
    appId = '$appIdPrefix.android';
  }

  await client.addPusher(appId, token, name, appName, pushServerUrl, Platform.isIOS, null);

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