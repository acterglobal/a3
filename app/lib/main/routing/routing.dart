import 'package:acter/common/dialogs/dialog_page.dart';
import 'package:acter/common/dialogs/error.dart';
import 'package:acter/common/dialogs/side_sheet_page.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/activities/pages/activities_page.dart';
import 'package:acter/features/bug_report/pages/bug_report_page.dart';
import 'package:acter/features/chat/pages/chat_page.dart';
import 'package:acter/features/gallery/pages/gallery_page.dart';
import 'package:acter/features/home/pages/dashboard.dart';
import 'package:acter/features/home/pages/home_shell.dart';
import 'package:acter/features/news/pages/news_page.dart';
import 'package:acter/features/onboarding/pages/login_page.dart';
import 'package:acter/features/onboarding/pages/sign_up_page.dart';
import 'package:acter/features/profile/pages/my_profile_page.dart';
import 'package:acter/features/search/pages/quick_jump.dart';
import 'package:acter/features/search/pages/search.dart';
import 'package:acter/features/settings/pages/index_page.dart';
import 'package:acter/features/settings/pages/info_page.dart';
import 'package:acter/features/settings/pages/labs_page.dart';
import 'package:acter/features/settings/pages/licenses_page.dart';
import 'package:acter/features/space/pages/overview_page.dart';
import 'package:acter/features/space/pages/shell_page.dart';
import 'package:acter/features/todo/pages/create_task_sidesheet.dart';
import 'package:acter/main/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// ignore: implementation_imports
import 'package:go_router/src/information_provider.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');
final GlobalKey<NavigatorState> _spaceNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'space');

final _routes = [
  GoRoute(
    name: Routes.authLogin.name,
    path: Routes.authLogin.route,
    builder: (context, state) => const LoginPage(),
  ),
  GoRoute(
    name: Routes.authRegister.name,
    path: Routes.authRegister.route,
    builder: (context, state) => const SignupPage(),
  ),
  GoRoute(
    path: '/gallery',
    builder: (context, state) => const GalleryPage(),
  ),
  GoRoute(
    parentNavigatorKey: _rootNavigatorKey,
    name: Routes.bugReport.name,
    path: Routes.bugReport.route,
    pageBuilder: (context, state) => DialogPage(
      builder: (_) => BugReportPage(imagePath: state.queryParams['screenshot']),
    ),
  ),
  GoRoute(
    parentNavigatorKey: _rootNavigatorKey,
    name: Routes.quickJump.name,
    path: Routes.quickJump.route,
    pageBuilder: (context, state) => DialogPage(
      builder: (_) => const QuickjumpDialog(),
    ),
  ),
  GoRoute(
    parentNavigatorKey: _rootNavigatorKey,
    name: Routes.actionAddTask.name,
    path: Routes.actionAddTask.route,
    pageBuilder: (context, state) {
      return SideSheetPage(
        key: state.pageKey,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween(
              begin: const Offset(1, 0),
              end: const Offset(0, 0),
            ).animate(
              animation,
            ),
            child: child,
          );
        },
        child: const AddTaskActionSideSheet(),
      );
    },
  ),

  /// Application shell
  ShellRoute(
    navigatorKey: _shellNavigatorKey,
    pageBuilder: (context, state, child) {
      return NoTransitionPage(
        key: state.pageKey,
        child: HomeShell(child: child),
      );
    },
    routes: <RouteBase>[
      GoRoute(
        name: Routes.myProfile.name,
        path: Routes.myProfile.route,
        pageBuilder: (context, state) {
          return NoTransitionPage(
            key: state.pageKey,
            child: const MyProfile(),
          );
        },
      ),
      GoRoute(
        name: Routes.activities.name,
        path: Routes.activities.route,
        pageBuilder: (context, state) {
          return NoTransitionPage(
            key: state.pageKey,
            child: const ActivitiesPage(),
          );
        },
      ),

      GoRoute(
        name: Routes.updates.name,
        path: Routes.updates.route,
        pageBuilder: (context, state) {
          return NoTransitionPage(
            key: state.pageKey,
            child: const NewsPage(),
          );
        },
      ),

      

      GoRoute(
        name: Routes.search.name,
        path: Routes.search.route,
        pageBuilder: (context, state) {
          return NoTransitionPage(
            key: state.pageKey,
            child: const SearchPage(),
          );
        },
      ),
      GoRoute(
        name: Routes.chatroom.name,
        path: Routes.chatroom.route,
        pageBuilder: (context, state) {
          return NoTransitionPage(key: state.pageKey, child: const ChatPage());
        },
      ),

      GoRoute(
        name: Routes.chat.name,
        path: Routes.chat.route,
        pageBuilder: (context, state) {
          return NoTransitionPage(key: state.pageKey, child: const ChatPage());
        },
      ),

      GoRoute(
        name: Routes.dashboard.name,
        path: Routes.dashboard.route,
        pageBuilder: (context, state) {
          return NoTransitionPage(key: state.pageKey, child: const Dashboard());
        },
      ),

      // ---- SETTINGS

      GoRoute(
        name: Routes.info.name,
        path: Routes.info.route,
        pageBuilder: (context, state) {
          return NoTransitionPage(
            key: state.pageKey,
            child: const SettingsInfoPage(),
          );
        },
      ),
      GoRoute(
        name: Routes.licenses.name,
        path: Routes.licenses.route,
        pageBuilder: (context, state) {
          return NoTransitionPage(
            key: state.pageKey,
            child: const SettingsLicensesPage(),
          );
        },
      ),

      GoRoute(
        name: Routes.settings.name,
        path: Routes.settings.route,
        pageBuilder: (context, state) {
          return NoTransitionPage(
            key: state.pageKey,
            child: const SettingsMenuPage(),
          );
        },
      ),

      GoRoute(
        name: Routes.settingsLabs.name,
        path: Routes.settingsLabs.route,
        pageBuilder: (context, state) {
          return NoTransitionPage(
            key: state.pageKey,
            child: const SettingsLabsPage(),
          );
        },
      ),

      /// Space subshell
      ShellRoute(
        navigatorKey: _spaceNavigatorKey,
        pageBuilder: (context, state, child) {
          return NoTransitionPage(
            key: state.pageKey,
            child: SpaceShell(
              spaceIdOrAlias: state.params['spaceId']!,
              child: child,
            ),
          );
        },
        routes: <RouteBase>[
          GoRoute(
            name: Routes.space.name,
            path: Routes.space.route,
            pageBuilder: (context, state) {
              return NoTransitionPage(
                key: state.pageKey,
                child: SpaceOverview(spaceIdOrAlias: state.params['spaceId']!),
              );
            },
          ),
        ],
      ),

      GoRoute(
        name: Routes.main.name,
        path: Routes.main.route,
        redirect: (BuildContext context, GoRouterState state) {
          if (isDesktop(context)) {
            return Routes.dashboard.route;
          } else {
            return Routes.updates.route;
          }
        },
      ),
    ],
  ),
];

class RouterNotifier extends AutoDisposeAsyncNotifier<void>
    implements Listenable {
  VoidCallback? routerListener;

  final routes = _routes;

  @override
  Future<void> build() async {
    ref.listenSelf((_, __) {
      // One could write more conditional logic for when to call redirection
      routerListener?.call();
    });
  }

  /// Adds [GoRouter]'s listener as specified by its [Listenable].
  /// [GoRouteInformationProvider] uses this method on creation to handle its
  /// internal [ChangeNotifier].
  /// Check out the internal implementation of [GoRouter] and
  /// [GoRouteInformationProvider] to see this in action.
  @override
  void addListener(VoidCallback listener) {
    routerListener = listener;
  }

  /// Removes [GoRouter]'s listener as specified by its [Listenable].
  /// [GoRouteInformationProvider] uses this method when disposing,
  /// so that it removes its callback when destroyed.
  /// Check out the internal implementation of [GoRouter] and
  /// [GoRouteInformationProvider] to see this in action.
  @override
  void removeListener(VoidCallback listener) {
    routerListener = null;
  }
}

final routerNotifierProvider =
    AutoDisposeAsyncNotifierProvider<RouterNotifier, void>(() {
  return RouterNotifier();
});

final goRouterProvider = Provider.autoDispose<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider.notifier);
  return GoRouter(
    errorBuilder: (context, state) => ErrorPage(routerState: state),
    navigatorKey: _rootNavigatorKey,
    refreshListenable: notifier,
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: notifier.routes,
  );
});

final routeInformationProvider =
    ChangeNotifierProvider.autoDispose<GoRouteInformationProvider>((ref) {
  final router = ref.watch(goRouterProvider);
  return router.routeInformationProvider;
});

final currentRoutingLocation = Provider.autoDispose<String>((ref) {
  return ref.watch(routeInformationProvider).value.location ?? '/';
});
