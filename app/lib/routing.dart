import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/bug_report/pages/bug_report_page.dart';
import 'package:acter/features/gallery/pages/gallery_page.dart';
import 'package:acter/features/home/pages/home_page.dart';
import 'package:acter/features/onboarding/pages/login_page.dart';
import 'package:acter/features/onboarding/pages/sign_up_page.dart';
import 'package:acter/features/profile/pages/social_profile_page.dart';

import 'package:go_router/go_router.dart';

final _routes = [
  GoRoute(
    path: '/',
    builder: (context, state) => const HomePage(),
  ),
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
];

// GoRouter configuration
final router = GoRouter(
  initialLocation: '/',
  routes: _routes,
);
