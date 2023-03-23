import 'package:acter/features/bug_report/pages/bug_report_page.dart';
import 'package:acter/features/chat/pages/chat_page.dart';
import 'package:acter/features/gallery/pages/gallery_page.dart';
import 'package:acter/features/home/pages/home_page.dart';
import 'package:acter/features/onboarding/pages/login_page.dart';
import 'package:acter/features/onboarding/pages/sign_up_page.dart';
import 'package:acter/features/profile/pages/social_profile_page.dart';
import 'package:acter/features/news/pages/news_page.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final desktopPlatforms = [
  TargetPlatform.linux,
  TargetPlatform.macOS,
  TargetPlatform.windows
];

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

final _routes = [
  GoRoute(
    name: 'login',
    path: '/login',
    builder: (context, state) => const LoginPage(),
  ),
  GoRoute(
    name: 'my-profile',
    path: '/profile',
    builder: (context, state) => const SocialProfilePage(),
  ),
  GoRoute(
    name: 'signup',
    path: '/signup',
    builder: (context, state) => const SignupPage(),
  ),
  GoRoute(
    path: '/gallery',
    builder: (context, state) => const GalleryPage(),
  ),
  GoRoute(
    name: 'bug-report',
    path: '/bug_report',
    builder: (context, state) =>
        BugReportPage(imagePath: state.queryParams['screenshot']),
  ),

  /// Application shell
  ShellRoute(
    navigatorKey: _shellNavigatorKey,
    pageBuilder: (context, state, child) {
      return NoTransitionPage(
        key: state.pageKey,
        child: HomePage(child: child),
      );
    },
    routes: <RouteBase>[
      /// The first screen to display in the bottom navigation bar.
      GoRoute(
        name: 'updates',
        path: '/updates',
        pageBuilder: (context, state) {
          return NoTransitionPage(
            key: state.pageKey,
            child: const NewsPage(),
          );
        },
      ),

      GoRoute(
        name: 'chat',
        path: '/chat',
        pageBuilder: (context, state) {
          return NoTransitionPage(key: state.pageKey, child: const ChatPage());
        },
      ),

      GoRoute(
        name: 'dashboard',
        path: '/dashboard',
        pageBuilder: (context, state) {
          return NoTransitionPage(key: state.pageKey, child: const NewsPage());
        },
      ),

      GoRoute(
        name: 'space',
        path: '/:space([!#][^\/]+)', // !spaceId, #spaceName
        pageBuilder: (context, state) {
          return NoTransitionPage(key: state.pageKey, child: const NewsPage());
        },
      ),

      GoRoute(
        path: '/',
        name: 'main',
        redirect: (BuildContext context, GoRouterState state) {
          final bool isDesktop =
              desktopPlatforms.contains(Theme.of(context).platform);
          if (isDesktop) {
            return '/dashboard';
          } else {
            return '/updates';
          }
        },
      ),
    ],
  ),
];

// GoRouter configuration
final router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: _routes,
);
