import 'package:acter/common/notifications/notifications.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/activities/pages/activities_page.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter/router/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:logging/logging.dart';

final _log = Logger('a3::router::activities_shell');

List<RouteBase> makeActivitiesShellRoutes(ref) {
  return [
    GoRoute(
      name: Routes.activities.name,
      path: Routes.activities.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: const ActivitiesPage(),
        );
      },
      onExit: (BuildContext context) {
        if (!context.read(
          isActiveProvider(LabsFeature.mobilePushNotifications),
        )) {
          return true;
        }
        _log.info('Attempting to ask for push notifications');
        final client = context.read(clientProvider);
        if (client != null) {
          setupPushNotifications(client);
        }
        return true;
      },
    ),
  ];
}
