import 'dart:io';

import 'package:acter/common/providers/app_state_provider.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/config/env.g.dart';
import 'package:acter/config/notifications/firebase_options.dart';
import 'package:acter/config/notifications/util.dart';
import 'package:acter/config/setup.dart';
import 'package:acter/features/notifications/providers/notification_settings_providers.dart';
import 'package:acter/router/router.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/acter_notifify.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::config::notifications');

const appIdPrefix = Env.pushAppPrefix;
const appName = Env.pushAppName;
const pushServer = Env.pushServer;
const ntfyServer = Env.ntfyServer;

Future<String?> initializeNotifications() async {
  final initialLocationFromNotification = await initializeNotifify(
    androidFirebaseOptions: DefaultFirebaseOptions.android,
    handleMessageTap: _handleMessageTap,
    isEnabledCheck: _isEnabled,
    shouldShowCheck: _shouldShow,
    appName: appName,
    appIdPrefix: appIdPrefix,
    pushServer: pushServer,
    ntfyServer: ntfyServer,
    winApplicationId:
        Env.windowsApplicationId.isNotEmpty ? Env.windowsApplicationId : null,
    currentClientsGen: _genCurrentClients,
  );

  if (initialLocationFromNotification != null) {
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      // push after the next render to ensure we still have the "initial" location
      goRouter.push(initialLocationFromNotification);
    });
  }
  return initialLocationFromNotification;
}

Future<bool> setupPushNotifications(Client client, {forced = false}) async {
  if ((Platform.isAndroid || Platform.isIOS)) {
    if (pushServer.isEmpty) {
      // no server given. Ignoring
      _log.warning(
        'No push server configured. Skipping push notification setup.',
      );
      return false;
    }
  } else if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    if (ntfyServer.isEmpty) {
      // no server given. Ignoring
      _log.warning('No NTFY server configured. Skipping notification setup.');
      return false;
    }
  } else {
    // not supported
    _log.warning('Notifications not supported on this platform');
    return false;
  }

  final deviceId = client.deviceId().toString();
  if (!forced && await wasRejected(deviceId)) {
    // If the user rejected and we aren’t asked to force, don’t bother them again.
    return false;
  }

  // this show some extra dialog here on devices where necessary
  final requested = await setupNotificationsForDevice(
    client,
    appName: appName,
    appIdPrefix: appIdPrefix,
    pushServer: pushServer,
    ntfyServer: ntfyServer,
  );
  if (requested == false) {
    // we were bluntly rejected, save and don’t bother them again:
    await setRejected(deviceId, true);
  }
  return requested != null;
}

bool _handleMessageTap(Map<String?, Object?> data) {
  final context = rootNavKey.currentContext;
  if (context == null) {
    // no context "et", delay by 300ms and try again;
    Future.delayed(
      const Duration(milliseconds: 300),
      () => _handleMessageTap(data),
    );
    return false;
  }
  return _handleMessageTapForContext(context, data);
}

bool _handleMessageTapForContext(
  BuildContext context,
  Map<String?, Object?> data,
) {
  _log.info('Notification  was tapped. Data: \n $data');
  try {
    final uri = data['payload'] as String?;
    if (uri != null) {
      _log.info('Uri found $uri');
      if (isCurrentRoute(uri)) {
        // ensure we reload
        context.replace(uri);
      } else {
        _log.info('Different page, routing');
        if (shouldReplaceCurrentRoute(uri)) {
          // this is a chat-room page, replace this to allow for
          // a smother "back"-navigation story
          context.pushReplacement(uri);
        } else {
          context.push(uri);
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
    context.push(
      makeForward(roomId: roomId, deviceId: deviceId, eventId: eventId),
    );
  } catch (e, s) {
    _log.severe('Handling Notification tap failed', e, s);
  }

  return true;
}

Future<bool> _isEnabled() async {
  try {
    // ignore: use_build_context_synchronously
    if (!await mainProviderContainer.read(
      isPushNotificationsActiveProvider.future,
    )) {
      _log.info(
        'Showing push notifications has been disabled on this device. Ignoring',
      );
      return false;
    }
  } catch (e, s) {
    _log.severe('Reading current context failed', e, s);
  }
  return true;
}

bool _shouldShow(String url) {
  // we ignore if we are in foreground and looking at that URL
  if (isCurrentRoute(url) &&
      // ignore: use_build_context_synchronously
      mainProviderContainer.read(isAppInForeground)) {
    return false;
  }
  return true;
}

Future<List<Client>> _genCurrentClients() async {
  _log.info(
    'Received the update information for the token. Updating all clients.',
  );
  List<Client> clients = [];
  final sdk = await mainProviderContainer.read(sdkProvider.future);

  for (final client in sdk.clients) {
    final deviceId = client.deviceId().toString();
    if (!await wasRejected(deviceId)) {
      _log.info('$deviceId was ignored for token update');
      clients.add(client);
    }
  }
  return clients;
}
