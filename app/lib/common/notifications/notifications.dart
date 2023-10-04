import 'dart:io';
import 'dart:convert';

import 'package:convert/convert.dart';

import 'package:acter/common/notifications/models.dart';
import 'package:acter/router/router.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:push/push.dart';
import 'package:device_info_plus/device_info_plus.dart';

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

const pushServerUrl = 'https://$pushServer/_matrix/push/v1/notify';

Future<void> initializeNotifications() async {
  // Handle notification launching app from terminated state
  Push.instance.notificationTapWhichLaunchedAppFromTerminated.then((data) {
    if (data == null) {
      debugPrint("App was not launched by tapping a notification");
    } else {
      debugPrint('Notification tap launched app from terminated state:\n'
          'RemoteMessage: ${data} \n');
    }
    // notificationWhichLaunchedApp.value = data;
  });

  // Handle notification taps
  Push.instance.onNotificationTap.listen((data) {
    debugPrint('Notification was tapped:\n'
        'Data: ${data} \n');
    // tappedNotificationPayloads.value += [data];
  });

  // Handle push notifications
  Push.instance.onMessage.listen((message) {
    debugPrint('RemoteMessage received while app is in foreground:\n'
        'RemoteMessage.Notification: ${message.notification} \n'
        ' title: ${message.notification?.title.toString()}\n'
        ' body: ${message.notification?.body.toString()}\n'
        'RemoteMessage.Data: ${message.data}');
    // messagesReceived.value += [message];
  });

  // Handle push notifications from
  Push.instance.onBackgroundMessage.listen((message) {
    debugPrint('RemoteMessage received while app is in background:\n'
        'RemoteMessage.Notification: ${message.notification} \n'
        ' title: ${message.notification?.title.toString()}\n'
        ' body: ${message.notification?.body.toString()}\n'
        'RemoteMessage.Data: ${message.data}');
    // backgroundMessagesReceived.value += [message];
  });

}

Future<bool> setupPushNotifications(
  Client client, {
  forced = false,
}) async {
  if (!(Platform.isAndroid || Platform.isIOS)) {
    // we are only supporting this on a limited set of platforms at the moment.
    return false;
  }
  if (pushServer.isEmpty) {
    // no server given. Ignoring
    return false;
  }

  // To be informed that the device's token has been updated by the operating system
  // You should update your servers with this token
  Push.instance.onNewToken.listen((token) {
    // FIXME: how to identify which clients are connected to this?
    debugPrint("Just got a new FCM registration token: ${token}");
    onNewToken(client, token);
  });

  final deviceId = client.deviceId().toString();
  final SharedPreferences preferences = await sharedPrefs();
  final prefKey = '$deviceId.rejected_notifications';

  String? token = await Push.instance.token;
  // do we already have a token, then no need to bother the user again
  if (token == null) {
    // check whether we were already rejected and thus shouldn't ask again
    if (!forced && (preferences.getBool(prefKey) ?? false)) {
      // we need to be forced to continue
      return false;
    }
    // TASK: show some extra dialog here?
    final requested = await Push.instance.requestPermission();
    if (!requested) {
      // we were bluntly rejected, save and don't them bother again:
      preferences.setBool(prefKey, false);
      return false;
    }
    token = await Push.instance.token;
  }

  if (token == null) {
    return false;
  }

  return await onNewToken(client, token);
}

Future<bool> onNewToken(Client client, String token) async {

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
}
