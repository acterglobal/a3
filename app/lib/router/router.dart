import 'package:acter/common/pages/not_found.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/home/pages/home_shell.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/router/general_router.dart';
import 'package:acter/router/shell_routers/activities_shell_router.dart';
import 'package:acter/router/shell_routers/chat_shell_router.dart';
import 'package:acter/router/shell_routers/home_shell_router.dart';
import 'package:acter/router/shell_routers/search_shell_router.dart';
import 'package:acter/router/shell_routers/update_shell_router.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/cupertino.dart';
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
  } catch (error, trace) {
    _log.severe('AuthGuard Fatal error', error, trace);
    return state.namedLocation(
      Routes.fatalFail.name,
      queryParameters: {'error': error.toString(), 'trace': trace.toString()},
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
      final deviceId = state.uri.queryParameters['deviceId'];
      client = await acterSdk.getClientWithDeviceId(deviceId!, true);
      // ignore: use_build_context_synchronously
      final ref = ProviderScope.containerOf(context);
      // ensure we have selected the right client
      ref.invalidate(clientProvider);
    } catch (error, trace) {
      _log.severe('Client not found', error, trace);
      return null;
    }
    final roomId = state.uri.queryParameters['roomId'];
    if (await client.hasConvo(roomId!)) {
      // this is a chat
      return state.namedLocation(
        Routes.chatroom.name,
        pathParameters: {'roomId': roomId},
      );
    } else {
      // final eventId = state.uri.queryParameters['eventId'];
      // with the event ID or further information we could figure out the specific action
      return state.namedLocation(
        Routes.space.name,
        pathParameters: {'spaceId': roomId},
      );
    }
  } catch (error, trace) {
    _log.severe('Forward fail', error, trace);
    return state.namedLocation(
      Routes.fatalFail.name,
      queryParameters: {'error': error.toString(), 'trace': trace.toString()},
    );
  }
}

final GlobalKey<NavigatorState> rootNavKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final homeShellKey = GlobalKey(debugLabel: 'home-shell');

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
  initialLocation: '/',
  routes: [
    ...generalRoutes,
    StatefulShellRoute.indexedStack(
      parentNavigatorKey: rootNavKey,
      builder: (
        BuildContext context,
        GoRouterState state,
        StatefulNavigationShell navigationShell,
      ) {
        return HomeShell(key: homeShellKey, navigationShell: navigationShell);
      },
      branches: shellBranches,
    ),
  ],
);
