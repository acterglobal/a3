import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/pages/not_found.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/main/app_shell.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/router/general_router.dart';
import 'package:acter/router/shell_routers/activities_shell_router.dart';
import 'package:acter/router/shell_routers/chat_shell_router.dart';
import 'package:acter/router/shell_routers/home_shell_router.dart';
import 'package:acter/router/shell_routers/search_shell_router.dart';
import 'package:acter/router/shell_routers/update_shell_router.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::router');

Future<String?> authGuardRedirect(
  BuildContext context,
  GoRouterState state,
) async {
  try {
    final acterSdk = await ActerSdk.instance;
    if (acterSdk.hasClients) {
      // we are all fine, we have a client, do go on.
      return null;
    }

    if (autoGuestLogin) {
      // if compiled with auto-guest-login, create an account
      await acterSdk.newGuestClient(setAsCurrent: true);
      return null;
    }
  } catch (e, s) {
    _log.severe('AuthGuard Fatal error', e, s);
    return state.namedLocation(
      Routes.fatalFail.name,
      queryParameters: {'error': e.toString(), 'trace': s.toString()},
    );
  }

  // no client found yet, send user to fresh login

  // next param calculation
  final next = Uri.encodeComponent(state.uri.toString());

  // ignore: deprecated_member_use
  return state.namedLocation(
    Routes.intro.name,
    queryParameters: {'next': next},
  );
}

Future<String?> forwardRedirect(
  BuildContext context,
  GoRouterState state,
) async {
  try {
    final acterSdk = await ActerSdk.instance;
    if (!acterSdk.hasClients) {
      // we are not logged in.
      return null;
    }
    Client client;
    try {
      final deviceId = state.uri.queryParameters['deviceId']
          .expect('query params should contain device id');
      client = await acterSdk.getClientWithDeviceId(deviceId, true);
    } catch (e, s) {
      _log.severe('Specified Client not found', e, s);
      final currentClient = acterSdk.currentClient;
      if (currentClient == null) {
        // we have no client at all, forward through login
        final next = Uri.encodeComponent(state.uri.toString());

        // ignore: deprecated_member_use
        return state.namedLocation(
          Routes.intro.name,
          queryParameters: {'next': next},
        );
      }
      client = currentClient; // continuing with the client we did find
    }

    // ignore: use_build_context_synchronously
    final ref = ProviderScope.containerOf(context);
    // ensure we have selected the right client
    ref.read(clientProvider.notifier).setClient(client);

    final roomId = state.uri.queryParameters['roomId'];
    if (roomId == null) {
      _log.severe(
        'Received forward without roomId failed: ${state.uri.queryParameters}.',
      );
      return state.namedLocation(Routes.main.name);
    }

    final room = await client.room(roomId);
    if (!room.isJoined()) {
      // we haven’t joined yet or have been kicked
      // either way, we are to be shown the thing on the activities page
      return state.namedLocation(
        Routes.myOpenInvitations.name,
        queryParameters: state.uri.queryParameters,
      );
    }

    if (room.isSpace()) {
      // final eventId = state.uri.queryParameters['eventId'];
      // with the event ID or further information we could figure out the specific action
      return state.namedLocation(
        Routes.space.name,
        pathParameters: {'spaceId': roomId},
      );
    }
    // so we assume this is a chat
    return state.namedLocation(
      Routes.chatroom.name,
      pathParameters: {'roomId': roomId},
    );
  } catch (e, s) {
    _log.severe('Forward fail', e, s);
    return state.namedLocation(
      Routes.fatalFail.name,
      queryParameters: {'error': e.toString(), 'trace': s.toString()},
    );
  }
}

Page defaultPageBuilder({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) =>
    context.isLargeScreen
        ? NoTransitionPage(
            key: state.pageKey,
            child: child,
          )
        : MaterialPage(
            key: state.pageKey,
            child: child,
          );

final GlobalKey<NavigatorState> rootNavKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final appShellKey = GlobalKey(debugLabel: 'home-shell');

final GlobalKey<NavigatorState> homeTabNavKey = GlobalKey<NavigatorState>(
  debugLabel: 'homeTabNavKey',
);
final GlobalKey<NavigatorState> updateTabNavKey = GlobalKey<NavigatorState>(
  debugLabel: 'updateTabNavKey',
);
final GlobalKey<NavigatorState> chatTabNavKey = GlobalKey<NavigatorState>(
  debugLabel: 'chatTabNavKey',
);
final GlobalKey<NavigatorState> activitiesTabNavKey = GlobalKey<NavigatorState>(
  debugLabel: 'activitiesTabNavKey',
);
final GlobalKey<NavigatorState> searchTabNavKey = GlobalKey<NavigatorState>(
  debugLabel: 'searchTabNavKey',
);

final shellBranches = [
  StatefulShellBranch(
    navigatorKey: homeTabNavKey,
    routes: homeShellRoutes,
  ),
  StatefulShellBranch(
    navigatorKey: updateTabNavKey,
    routes: updateShellRoutes,
  ),
  StatefulShellBranch(
    navigatorKey: chatTabNavKey,
    routes: chatShellRoutes,
  ),
  StatefulShellBranch(
    navigatorKey: activitiesTabNavKey,
    routes: activitiesShellRoutes,
  ),
  StatefulShellBranch(
    navigatorKey: searchTabNavKey,
    routes: searchShellRoutes,
  ),
];

final goRouter = GoRouter(
  errorBuilder: (context, state) => NotFoundPage(routerState: state),
  navigatorKey: rootNavKey,
  initialLocation: Routes.main.route,
  restorationScopeId: 'acter-routes',
  routes: [
    ...generalRoutes,
    StatefulShellRoute.indexedStack(
      parentNavigatorKey: rootNavKey,
      builder: (
        BuildContext context,
        GoRouterState state,
        StatefulNavigationShell navigationShell,
      ) {
        return AppShell(key: appShellKey, navigationShell: navigationShell);
      },
      branches: shellBranches,
    ),
  ],
);
