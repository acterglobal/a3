import 'dart:io';

import 'package:acter/common/notifications/notifications.dart';
import 'package:acter/router/router.dart';
import 'package:go_router/go_router.dart';

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
  final router = GoRouter.of(rootNavKey.currentContext!);
  final currentUri = router.routeInformationProvider.value.uri;
  return currentUri.path == uri;
}
