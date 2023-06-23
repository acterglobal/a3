import 'package:acter/common/dialogs/dialog_page.dart';
import 'package:acter/common/dialogs/side_sheet_page.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/activities/presentation/pages/activities_page.dart';
import 'package:acter/features/bug_report/pages/bug_report_page.dart';
import 'package:acter/features/chat/pages/chat_page.dart';
import 'package:acter/features/gallery/pages/gallery_page.dart';
import 'package:acter/features/home/pages/dashboard.dart';
import 'package:acter/features/home/pages/home_shell.dart';
import 'package:acter/features/home/widgets/create_space_sheet.dart';
import 'package:acter/features/news/pages/news_builder_page.dart';
import 'package:acter/features/news/pages/news_page.dart';
import 'package:acter/features/news/pages/post_page.dart';
import 'package:acter/features/news/pages/search_space_page.dart';
import 'package:acter/features/onboarding/pages/login_page.dart';
import 'package:acter/features/onboarding/pages/register_page.dart';
import 'package:acter/features/onboarding/pages/start_page.dart';
import 'package:acter/features/profile/pages/my_profile_page.dart';
import 'package:acter/features/todo/pages/todo_page.dart';
import 'package:acter/features/search/pages/quick_jump.dart';
import 'package:acter/features/search/pages/search.dart';
import 'package:acter/features/settings/pages/index_page.dart';
import 'package:acter/features/settings/pages/info_page.dart';
import 'package:acter/features/settings/pages/labs_page.dart';
import 'package:acter/features/settings/pages/licenses_page.dart';
import 'package:acter/features/space/pages/overview_page.dart';
import 'package:acter/features/space/pages/shell_page.dart';
import 'package:acter/features/todo/pages/create_task_sidesheet.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// ignore: implementation_imports
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter/common/utils/constants.dart';

Future<String?> authGuardRedirect(
  BuildContext context,
  GoRouterState state,
) async {
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

  // no client found yet, send user to fresh login

  // next param calculation
  final next = Uri.encodeComponent(state.location);

  // ignore: deprecated_member_use
  return state.namedLocation(
    Routes.start.name,
    queryParams: {'next': next},
  );
}

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');
final GlobalKey<NavigatorState> spaceNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'space');

final routes = [
  GoRoute(
    name: Routes.start.name,
    path: Routes.start.route,
    builder: (context, state) => const StartPage(),
  ),
  GoRoute(
    name: Routes.authLogin.name,
    path: Routes.authLogin.route,
    builder: (context, state) => const LoginPage(),
  ),
  GoRoute(
    name: Routes.authRegister.name,
    path: Routes.authRegister.route,
    builder: (context, state) => const RegisterPage(),
  ),
  GoRoute(
    path: '/gallery',
    builder: (context, state) => const GalleryPage(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    name: Routes.bugReport.name,
    path: Routes.bugReport.route,
    pageBuilder: (context, state) => DialogPage(
      builder: (_) => BugReportPage(imagePath: state.queryParams['screenshot']),
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    name: Routes.quickJump.name,
    path: Routes.quickJump.route,
    pageBuilder: (context, state) => DialogPage(
      builder: (_) => const QuickjumpDialog(),
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
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
    navigatorKey: shellNavigatorKey,
    // FIXME: unfortunately ShellRoute doesn't support redirects yet,
    // thus we have to put it onto every route. Once that is fixed,
    // remove that param from the sub-routes and use only here instead
    // ref: https://github.com/flutter/flutter/issues/114559
    // redirect: authGuardRedirect,

    pageBuilder: (context, state, child) {
      return NoTransitionPage(
        key: state.pageKey,
        child: HomeShell(child: child),
      );
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/gallery',
        builder: (context, state) => const GalleryPage(),
      ),
      GoRoute(
        name: Routes.myProfile.name,
        path: Routes.myProfile.route,
        redirect: authGuardRedirect,
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
        redirect: authGuardRedirect,
        pageBuilder: (context, state) {
          return NoTransitionPage(
            key: state.pageKey,
            child: const ActivitiesPage(),
          );
        },
      ),

      GoRoute(
        name: Routes.tasks.name,
        path: Routes.tasks.route,
        redirect: authGuardRedirect,
        pageBuilder: (context, state) {
          return NoTransitionPage(
            key: state.pageKey,
            child: const TodoPage(),
          );
        },
      ),
      GoRoute(
        name: Routes.updates.name,
        path: Routes.updates.route,
        redirect: authGuardRedirect,
        pageBuilder: (context, state) {
          return NoTransitionPage(
            key: state.pageKey,
            child: const NewsPage(),
          );
        },
        routes: <RouteBase>[
          // hide bottom nav for nested pages, use rootNavigatorKey
          GoRoute(
            parentNavigatorKey: rootNavigatorKey,
            name: Routes.updatesEdit.name,
            path: Routes.updatesEdit.route,
            redirect: authGuardRedirect,
            pageBuilder: (context, state) {
              return NoTransitionPage(
                key: state.pageKey,
                child: const NewsBuilderPage(),
              );
            },
          ),
          GoRoute(
            parentNavigatorKey: rootNavigatorKey,
            name: Routes.updatesPost.name,
            path: Routes.updatesPost.route,
            redirect: authGuardRedirect,
            pageBuilder: (context, state) {
              return NoTransitionPage(
                key: state.pageKey,
                child: PostPage(
                  attachmentUri: state.extra as String?,
                ),
              );
            },
            routes: <RouteBase>[
              GoRoute(
                parentNavigatorKey: rootNavigatorKey,
                name: Routes.updatesPostSearch.name,
                path: Routes.updatesPostSearch.route,
                redirect: authGuardRedirect,
                pageBuilder: (context, state) {
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: const SearchSpacePage(),
                  );
                },
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        name: Routes.search.name,
        path: Routes.search.route,
        redirect: authGuardRedirect,
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
        redirect: authGuardRedirect,
        pageBuilder: (context, state) {
          return NoTransitionPage(key: state.pageKey, child: const ChatPage());
        },
      ),

      GoRoute(
        name: Routes.chat.name,
        path: Routes.chat.route,
        redirect: authGuardRedirect,
        pageBuilder: (context, state) {
          return NoTransitionPage(key: state.pageKey, child: const ChatPage());
        },
      ),

      GoRoute(
        name: Routes.dashboard.name,
        path: Routes.dashboard.route,
        redirect: authGuardRedirect,
        pageBuilder: (context, state) {
          return NoTransitionPage(key: state.pageKey, child: const Dashboard());
        },
        routes: <RouteBase>[
          GoRoute(
            parentNavigatorKey: rootNavigatorKey,
            name: Routes.createSpace.name,
            path: Routes.createSpace.route,
            redirect: authGuardRedirect,
            pageBuilder: (context, state) {
              return NoTransitionPage(
                key: state.pageKey,
                child: const CreateSpacePage(),
              );
            },
          )
        ],
      ),

      // ---- SETTINGS

      GoRoute(
        name: Routes.info.name,
        path: Routes.info.route,
        redirect: authGuardRedirect,
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
        redirect: authGuardRedirect,
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
        redirect: authGuardRedirect,
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
        redirect: authGuardRedirect,
        pageBuilder: (context, state) {
          return NoTransitionPage(
            key: state.pageKey,
            child: const SettingsLabsPage(),
          );
        },
      ),

      /// Space subshell
      ShellRoute(
        navigatorKey: spaceNavigatorKey,
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
            redirect: authGuardRedirect,
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
        redirect: (BuildContext context, GoRouterState state) async {
          // we first check if there is a client available for us to use
          final authGuarded = await authGuardRedirect(context, state);
          if (authGuarded != null) {
            return authGuarded;
          }
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
