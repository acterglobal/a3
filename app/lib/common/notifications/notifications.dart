import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:acter/common/utils/utils.dart';
import 'package:acter/router/providers/router_providers.dart';
import 'package:acter/router/router.dart';
import 'package:go_router/go_router.dart';
import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

final supportedPlatforms =
    Platform.isAndroid || Platform.isIOS; // || Platform.isMacOS;

int id = 0;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Streams are created so that app can respond to notification-related events
/// since the plugin is initialised in the `main` function
final StreamController<ReceivedNotification> didReceiveLocalNotificationStream =
    StreamController<ReceivedNotification>.broadcast();

final StreamController<String?> selectNotificationStream =
    StreamController<String?>.broadcast();

const MethodChannel platform = MethodChannel('acter/push_notification');

const String portName = 'notification_send_port';

class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;
}

String? selectedNotificationPayload;

/// A notification action which triggers a url launch event
const String urlLaunchActionId = 'id_1';

/// A notification action which triggers a App navigation event
const String navigationActionId = 'id_3';

/// Defines a iOS/MacOS notification category for text input actions.
const String darwinNotificationCategoryText = 'textCategory';

/// Defines a iOS/MacOS notification category for plain actions.
const String darwinNotificationCategoryPlain = 'plainCategory';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // ignore: avoid_print
  print('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    // ignore: avoid_print
    print(
      'notification action tapped with input: ${notificationResponse.input}',
    );
  }
}

String makeForward({
  required String roomId,
  required String deviceId,
  required String eventId,
}) {
  return '/forward?roomId=${Uri.encodeComponent(roomId)}&eventId=${Uri.encodeComponent(eventId)}&deviceId=${Uri.encodeComponent(deviceId)}';
}

Future<void> initializeNotifications() async {
  if (!supportedPlatforms) {
    return; // nothing for us to do here.
  }

  final NotificationAppLaunchDetails? notificationAppLaunchDetails = !kIsWeb &&
          Platform.isLinux
      ? null
      : await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    selectedNotificationPayload =
        notificationAppLaunchDetails!.notificationResponse?.payload;
  }

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');

  final List<DarwinNotificationCategory> darwinNotificationCategories =
      <DarwinNotificationCategory>[
    DarwinNotificationCategory(
      darwinNotificationCategoryText,
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.text(
          'text_1',
          'Action 1',
          buttonTitle: 'Send',
          placeholder: 'Placeholder',
        ),
      ],
    ),
    DarwinNotificationCategory(
      darwinNotificationCategoryPlain,
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain('id_1', 'Action 1'),
        DarwinNotificationAction.plain(
          'id_2',
          'Action 2 (destructive)',
          options: <DarwinNotificationActionOption>{
            DarwinNotificationActionOption.destructive,
          },
        ),
        DarwinNotificationAction.plain(
          navigationActionId,
          'Action 3 (foreground)',
          options: <DarwinNotificationActionOption>{
            DarwinNotificationActionOption.foreground,
          },
        ),
        DarwinNotificationAction.plain(
          'id_4',
          'Action 4 (auth required)',
          options: <DarwinNotificationActionOption>{
            DarwinNotificationActionOption.authenticationRequired,
          },
        ),
      ],
      options: <DarwinNotificationCategoryOption>{
        DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
      },
    ),
  ];

  /// Note: permissions aren't requested here just to demonstrate that can be
  /// done later
  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: false,
    requestSoundPermission: false,
    onDidReceiveLocalNotification:
        (int id, String? title, String? body, String? payload) async {
      didReceiveLocalNotificationStream.add(
        ReceivedNotification(
          id: id,
          title: title,
          body: body,
          payload: payload,
        ),
      );
    },
    notificationCategories: darwinNotificationCategories,
  );
  final LinuxInitializationSettings initializationSettingsLinux =
      LinuxInitializationSettings(
    defaultActionName: 'Open notification',
    defaultIcon: AssetsLinuxIcon('icons/app_icon.png'),
  );
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
    macOS: initializationSettingsDarwin,
    linux: initializationSettingsLinux,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) {
      switch (notificationResponse.notificationResponseType) {
        case NotificationResponseType.selectedNotification:
          selectNotificationStream.add(notificationResponse.payload);
          break;
        case NotificationResponseType.selectedNotificationAction:
          if (notificationResponse.actionId == navigationActionId) {
            selectNotificationStream.add(notificationResponse.payload);
          }
          break;
      }
    },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  // Handle notification launching app from terminated state
  Push.instance.notificationTapWhichLaunchedAppFromTerminated.then((data) {
    if (data == null) {
      debugPrint('App was not launched by tapping a notification');
    } else {
      debugPrint('Notification tap launched app from terminated state:\n'
          'RemoteMessage: $data \n');
    }
    // notificationWhichLaunchedApp.value = data;
  });

  // Handle notification taps
  try {
    Push.instance.onNotificationTap.listen((data) {
      debugPrint('Notification was tapped. Data: \n $data');
      final uri = data['payload'] as String?;
      if (uri != null) {
        debugPrint('Uri found $uri');
        rootNavKey.currentContext!.push(uri);
        return;
      }

      final roomId = data['room_id'] as String?;
      final eventId = data['event_id'] as String?;
      final deviceId = data['device_id'] as String?;
      if (roomId == null || eventId == null || deviceId == null) {
        debugPrint('Not our kind of push event. $roomId, $eventId, $deviceId');
        return;
      }
      rootNavKey.currentContext!.push(
        makeForward(roomId: roomId, deviceId: deviceId, eventId: eventId),
      );
    });

    // Handle push notifications
    Push.instance.onMessage.listen((message) async {
      await handleMessage(message, background: false);
    });

    // Handle push notifications on background - in iOS we are doing that in
    // the other instance.
    if (!Platform.isIOS) {
      Push.instance.onBackgroundMessage.listen((message) async {
        await handleMessage(message, background: true);
      });
    }
  } catch (e) {
    // this fails on hot-reload and in integration tests... if so, ignore for now
    debugPrint('Push initialization error: $e');
  }
}

Future<bool> handleMessage(
  RemoteMessage message, {
  bool background = false,
}) async {
  if (message.data == null) {
    debugPrint('non-matrix push: $message');
    return false;
  }
  final deviceId = message.data!['device_id'] as String;
  final roomId = message.data!['room_id'] as String;
  final eventId = message.data!['event_id'] as String;
  final payload =
      makeForward(roomId: roomId, deviceId: deviceId, eventId: eventId);
  try {
    final instance = await ActerSdk.instance;
    final notif = await instance.getNotificationFor(deviceId, roomId, eventId);
    final isDm = notif.isDirectMessageRoom();
    final roomDisplayName = notif.roomDisplayName();
    debugPrint('got a matrix notification in $roomDisplayName ($isDm)');

    String body = '(new message)';
    String title = roomDisplayName;

    if (isDm) {
      final roomMsg = notif.roomMessage();
      if (roomMsg != null) {
        final eventItem = roomMsg.eventItem();
        if (eventItem != null) {
          final textDesc = eventItem.textDesc();
          if (textDesc != null) {
            body = textDesc.body();
          }
        }
      }
    } else {
      final roomMsg = notif.roomMessage();
      if (roomMsg != null) {
        final eventItem = roomMsg.eventItem();
        if (eventItem != null) {
          final textDesc = eventItem.textDesc();
          if (textDesc != null) {
            body = textDesc.body();
          }
        }
      }

      final sender = notif.senderDisplayName();
      body = sender != null ? '$sender: $body' : body;
    }

    try {
      final currentBase =
          // ignore: use_build_context_synchronously
          rootNavKey.currentContext!.read(currentRoutingLocation);
      final isInChat = currentBase == '/chat/${Uri.encodeComponent(roomId)}';
      debugPrint('current path: $currentBase == /chat/$roomId : $isInChat');
      if (isInChat) {
        debugPrint('We are already in the chatroom. Not showing notification.');
        return false;
      }
    } catch (e) {
      // ignore this
    }

    _showNotification(title, body, roomId, payload);
    return true;
  } catch (e) {
    debugPrint('Parsing Notification failed: $e');
  }
  return false;
}

Future<void> _showNotification(
  String title,
  String body,
  String threadId,
  String payload,
) async {
  const androidNotificationDetails = AndroidNotificationDetails(
    'messages',
    'Messages',
    channelDescription: 'Messages sent to you',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
  );
  final darwinDetails = DarwinNotificationDetails(
    threadIdentifier: threadId,
  );
  final notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
    macOS: darwinDetails,
    iOS: darwinDetails,
  );
  await flutterLocalNotificationsPlugin.show(
    id++,
    title,
    body,
    notificationDetails,
    payload: payload,
  );
}

Future<bool> setupPushNotifications(
  Client client, {
  forced = false,
}) async {
  if (!supportedPlatforms) {
    return false; // nothing for us to do here.
  }
  if (pushServer.isEmpty) {
    // no server given. Ignoring
    return false;
  }

  // To be informed that the device's token has been updated by the operating system
  // You should update your servers with this token
  Push.instance.onNewToken.listen((token) {
    // FIXME: how to identify which clients are connected to this?
    debugPrint('Just got a new FCM registration token: $token');
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
    // sygnal expects token as a base64 encoded string, but we have a HEX from the plugin
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

  await client.addPusher(
    appId,
    token,
    name,
    appName,
    pushServerUrl,
    Platform.isIOS,
    null,
  );

  debugPrint(
    ' ---- notification pusher sent: $appName ($appId) on $name ($token) to $pushServerUrl',
  );

  return true;
}
