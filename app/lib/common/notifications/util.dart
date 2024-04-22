import 'dart:io';

import 'package:acter/common/notifications/notifications.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/router/providers/router_providers.dart';
import 'package:acter/router/router.dart';
import 'package:acter/router/utils.dart';

final isOnSupportedPlatform =
    Platform.isAndroid || Platform.isIOS; // || Platform.isMacOS;

Future<void> cancelInThread(String threadId) async {
  if (!isOnSupportedPlatform) {
    return; // nothing for us to do here.
  }

  final toCancel =
      (await flutterLocalNotificationsPlugin.getActiveNotifications())
          .where(
            (element) => element.groupKey == threadId,
          )
          .map(
            (e) => e.id,
          )
          .toList();

  for (final id in toCancel) {
    if (id != null) {
      await flutterLocalNotificationsPlugin.cancel(id);
    }
  }
}

bool isCurrentRoute(String uri) {
  final currentUri = rootNavKey.currentContext!.read(currentRoutingLocation);
  return currentUri == uri;
}

bool shouldReplaceCurrentRoute(String uri) {
  if (!uri.startsWith(chatRoomUriMatcher)) {
    return false;
  }

  final currentUri = rootNavKey.currentContext!.read(currentRoutingLocation);
  return currentUri.startsWith(chatRoomUriMatcher);
}
