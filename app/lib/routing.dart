import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/bug_report/pages/bug_report_page.dart';
import 'package:acter/features/gallery/pages/gallery_page.dart';
import 'package:acter/features/home/pages/home_page.dart';
import 'package:acter/features/onboarding/pages/login_page.dart';
import 'package:acter/features/onboarding/pages/sign_up_page.dart';
import 'package:acter/features/profile/pages/social_profile_page.dart';

import 'package:acter/features/chat/pages/chat_page.dart';
import 'package:acter/features/home/controllers/home_controller.dart';
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
    path: '/login',
    builder: (context, state) => const LoginPage(),
  ),
  GoRoute(
    path: '/profile',
    builder: (context, state) => const SocialProfilePage(),
  ),
  GoRoute(
    path: '/signup',
    builder: (context, state) => const SignupPage(),
  ),
  GoRoute(
    path: '/gallery',
    builder: (context, state) => const GalleryPage(),
  ),
  GoRoute(
    path: '/bug_report',
    builder: (context, state) =>
        BugReportPage(imagePath: state.queryParams['screenshot']),
  ),

  /// Application shell
  ShellRoute(
    navigatorKey: _shellNavigatorKey,
    builder: (BuildContext context, GoRouterState state, Widget child) {
      return HomePage(child: child);
    },
    routes: <RouteBase>[
      /// The first screen to display in the bottom navigation bar.
      GoRoute(
        path: '/news',
        builder: (BuildContext context, GoRouterState state) {
          return const NewsPage();
        },
      ),

      GoRoute(
        path: '/dashboard',
        builder: (BuildContext context, GoRouterState state) {
          return const NewsPage();
        },
      ),

      GoRoute(
        path: '/',
        redirect: (BuildContext context, GoRouterState state) {
          final bool isDesktop =
              desktopPlatforms.contains(Theme.of(context).platform);
          if (isDesktop) {
            return '/dashboard';
          } else {
            return '/news';
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
