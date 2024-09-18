import 'dart:io';

import 'package:acter/common/providers/app_state_provider.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/config/env.g.dart';
import 'package:acter/config/notifications/firebase_options.dart';
import 'package:acter/config/notifications/util.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter/router/router.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/acter_notifify.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::notifications');

const appIdPrefix = Env.pushAppPrefix;
const appName = Env.pushAppName;
const pushServer = Env.pushServer;
const ntfyServer = Env.ntfyServer;

Future<String?> initializeNotifications() async {
  return await initializeNotifify(
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
}

Future<bool> setupPushNotifications(
  Client client, {
  forced = false,
}) async {
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
      _log.warning(
        'No NTFY server configured. Skipping notification setup.',
      );
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
  _log.info('Notification was tapped. Data: \n $data');
  final curContext = rootNavKey.currentContext;
  if (curContext == null) throw 'Root context not available';
  try {
    final uri = data['payload'] as String?;
    if (uri != null) {
      _log.info('Uri found $uri');
      if (isCurrentRoute(uri)) {
        // ensure we reload
        curContext.replace(uri);
      } else {
        _log.info('Different page, routing');
        if (shouldReplaceCurrentRoute(uri)) {
          // this is a chat-room page, replace this to allow for
          // a smother "back"-navigation story
          curContext.pushReplacement(uri);
        } else {
          curContext.push(uri);
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
    curContext.push(
      makeForward(roomId: roomId, deviceId: deviceId, eventId: eventId),
    );
  } catch (e, s) {
    _log.severe('Handling Notification tap failed', e, s);
  }

  return true;
}

bool _isEnabled() {
  final curContext = rootNavKey.currentContext;
  if (curContext == null) throw 'Root context not available';
  try {
    // ignore: use_build_context_synchronously
    final pushActive =
        curContext.read(isActiveProvider(LabsFeature.mobilePushNotifications));
    if (!pushActive) {
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
  final curContext = rootNavKey.currentContext;
  if (curContext == null) throw 'Root context not available';
  // we ignore if we are in foreground and looking at that URL
  if (isCurrentRoute(url) &&
      // ignore: use_build_context_synchronously
      curContext.read(isAppInForeground)) {
    return false;
  }
  return true;
}

Future<List<Client>> _genCurrentClients() async {
  _log.info(
    'Received the update information for the token. Updating all clients.',
  );
  List<Client> clients = [];
  // ignore: use_build_context_synchronously
  final currentContext = rootNavKey.currentContext;
  if (currentContext == null) {
    _log.warning('No currentContext found. skipping setting of new token');
    return clients;
  }
  final sdk = await currentContext.read(sdkProvider.future);

  for (final client in sdk.clients) {
    final deviceId = client.deviceId().toString();
    if (!await wasRejected(deviceId)) {
      _log.info('$deviceId was ignored for token update');
      clients.add(client);
    }
  }
  return clients;
}
