import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:acter/common/notifications/android.dart';
import 'package:acter/common/notifications/util.dart';
import 'package:acter/common/providers/app_state_provider.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter/router/router.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:convert/convert.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:push/push.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _log = Logger('a3::notifications');

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

int id = 0; // global ID counter

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
  _log.info('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    // ignore: avoid_print
    _log.info(
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
  if (!isOnSupportedPlatform) {
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
      AndroidInitializationSettings('logo_notification');

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
    // do not bother the user at startup, set all these to falls for now:
    requestAlertPermission: false,
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

  try {
    // Handle notification launching app from terminated state
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

    // Handle push notifications
    Push.instance.addOnMessage((message) async {
      await handleMessage(message, background: false);
    });

    // Handle push notifications on background - in iOS we are doing that in
    // the other instance.
    if (!Platform.isIOS) {
      Push.instance.addOnBackgroundMessage((message) async {
        await handleMessage(message, background: true);
      });
    }

    // To be informed that the device's token has been updated by the operating system
    // You should update your servers with this token
    Push.instance.onNewToken.listen((token) {
      // FIXME: how to identify which clients are connected to this?
      _log.info('Just got a new FCM registration token: $token');
      onNewToken(token);
    });
  } catch (e, s) {
    // this fails on hot-reload and in integration tests... if so, ignore for now
    _log.warning('Push initialization error', e, s);
  }
}

bool handleMessageTap(Map<String?, Object?> data) {
  _log.info('Notification was tapped. Data: \n $data');
  try {
    final uri = data['payload'] as String?;
    if (uri != null) {
      _log.info('Uri found $uri');
      if (isCurrentRoute(uri)) {
        // ensure we reload
        rootNavKey.currentContext!.replace(uri);
      } else {
        _log.info('Different page, routing');
        if (shouldReplaceCurrentRoute(uri)) {
          // this is a chat-room page, replace this to allow for
          // a smother "back"-navigation story
          rootNavKey.currentContext!.pushReplacement(uri);
        } else {
          rootNavKey.currentContext!.push(uri);
        }
      }
      return true;
    }

    final roomId = data['room_id'] as String?;
    final eventId = data['event_id'] as String?;
    final deviceId = data['device_id'] as String?;
    if (roomId == null || eventId == null || deviceId == null) {
      _log.info('Not our kind of push event. $roomId, $eventId, $deviceId');
      return false;
    }
    // fallback support
    rootNavKey.currentContext!.push(
      makeForward(roomId: roomId, deviceId: deviceId, eventId: eventId),
    );
  } catch (e, s) {
    _log.severe('Handling Notification tap failed', e, s);
  }

  return true;
}

Future<bool> handleMessage(
  RemoteMessage message, {
  bool background = false,
}) async {
  try {
    // ignore: use_build_context_synchronously
    if (!rootNavKey.currentContext!
        .read(isActiveProvider(LabsFeature.mobilePushNotifications))) {
      _log.info(
        'Showing push notifications has been disabled on this device. Ignoring',
      );
      return false;
    }
  } catch (e, s) {
    _log.severe('Reading current context failed', e, s);
  }
  if (message.data == null) {
    _log.info('non-matrix push: $message');
    return false;
  }
  final deviceId = message.data!['device_id'] as String;
  final roomId = message.data!['room_id'] as String;
  final eventId = message.data!['event_id'] as String;
  _log.info('Received msg $roomId: $eventId');
  try {
    final instance = await ActerSdk.instance;
    final notification =
        await instance.getNotificationFor(deviceId, roomId, eventId);
    _log.info('got a notification');

    // we ignore if we are in foreground and looking at that URL
    if (isCurrentRoute(notification.targetUrl()) &&
        // ignore: use_build_context_synchronously
        rootNavKey.currentContext!.read(isAppInForeground)) {
      _log.info(
        'Ignoring notification: user is looking at this screen already',
      );
      return false;
    }
    await _showNotification(notification);
    return true;
  } catch (e, s) {
    _log.severe('Parsing Notification failed', e, s);
  }
  return false;
}

Future<void> removeNotificationsForRoom(String roomId) async {
  if (!isOnSupportedPlatform) {
    return; // nothing for us to do here.
  }
  await cancelInThread(roomId);
  if (Platform.isAndroid) {
    androidClearNotificationsCache(roomId);
  }
}

Future<void> _showNotification(
  NotificationItem notification,
) async {
  if (Platform.isAndroid) {
    return await showNotificationOnAndroid(notification);
  }
  // fallback for non-android
  String? body;
  String title = notification.title();
  List<DarwinNotificationAttachment> attachments = [];

  final msg = notification.body();
  if (msg != null) {
    body = msg.body();
  }
  // FIXME: currently failing with
  // Parsing Notification failed: PlatformException(Error 101, Unrecognized attachment file type, UNErrorDomain, null)
  if (notification.hasImage()) {
    final tempDir = await getTemporaryDirectory();
    final filePath = await notification.imagePath(tempDir.path);
    _log.info('attachment at $filePath');
    attachments.add(DarwinNotificationAttachment(filePath));
  }

  final darwinDetails = DarwinNotificationDetails(
    threadIdentifier: notification.threadId(),
    attachments: attachments,
  );
  final notificationDetails = NotificationDetails(
    macOS: darwinDetails,
    iOS: darwinDetails,
  );
  await flutterLocalNotificationsPlugin.show(
    id++,
    title,
    body,
    notificationDetails,
    payload: notification.targetUrl(),
  );
}

Future<bool> wasRejected(String deviceId) async {
  final SharedPreferences preferences = await sharedPrefs();
  final prefKey = '$deviceId.rejected_notifications';
  return preferences.getBool(prefKey) ?? false;
}

Future<void> setRejected(String deviceId, bool value) async {
  final SharedPreferences preferences = await sharedPrefs();
  final prefKey = '$deviceId.rejected_notifications';
  preferences.setBool(prefKey, value);
}

Future<bool> setupPushNotifications(
  Client client, {
  forced = false,
}) async {
  if (!isOnSupportedPlatform) {
    return false; // nothing for us to do here.
  }
  if (pushServer.isEmpty) {
    // no server given. Ignoring
    _log.warning(
      'No push server configured. Skipping push notification setup.',
    );
    return false;
  }

  final deviceId = client.deviceId().toString();
  if (!forced && await wasRejected(deviceId)) {
    // If the user rejected and we aren't asked to force, don't bother them again.
    return false;
  }
  // this show some extra dialog here on devices where necessary
  final requested = await Push.instance.requestPermission(
    badge: true,
    alert: true, // we request loud notifications now.
  );
  if (!requested) {
    // we were bluntly rejected, save and don't them bother again:
    await setRejected(deviceId, true);
    return false;
  }

  // let's get the token
  final token = await Push.instance.token;

  if (token == null) {
    _log.info('No token given');
    return false;
  }

  return await onToken(client, token);
}

Future<bool> onNewToken(String token) async {
  _log.info(
    'Received the update information for the token. Updating all clients.',
  );
  // ignore: use_build_context_synchronously
  final sdk = rootNavKey.currentContext!.read(sdkProvider).requireValue;

  for (final client in sdk.clients) {
    final deviceId = client.deviceId().toString();
    if (await wasRejected(deviceId)) {
      _log.info('$deviceId was ignored for token update');
      continue;
    }
    await onToken(client, token);
  }
  return true;
}

Future<bool> onToken(Client client, String token) async {
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
  } else if (Platform.isAndroid) {
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

  _log.info(
    ' ---- notification pusher set: $appName ($appId) on $name ($token) to $pushServerUrl',
  );

  await client.installDefaultActerPushRules();

  _log.info(
    ' ---- default push rules submitted',
  );
  return true;
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
