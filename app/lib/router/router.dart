import 'package:acter/common/dialogs/dialog_page.dart';
import 'package:acter/common/dialogs/side_sheet_page.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/activities/pages/activities_page.dart';
import 'package:acter/features/bug_report/pages/bug_report_page.dart';
import 'package:acter/features/chat/dialogs/create_chat_sheet.dart';
import 'package:acter/features/chat/pages/chat_page.dart';
import 'package:acter/features/chat/pages/room_profile_page.dart';
import 'package:acter/features/chat/pages/room_page.dart';
import 'package:acter/features/events/dialogs/create_event_sheet.dart';
import 'package:acter/features/events/dialogs/edit_event_sheet.dart';
import 'package:acter/features/events/pages/event_page.dart';
import 'package:acter/features/gallery/pages/gallery_page.dart';
import 'package:acter/features/home/pages/dashboard.dart';
import 'package:acter/features/home/pages/home_shell.dart';
import 'package:acter/features/space/pages/members_page.dart';
import 'package:acter/features/news/pages/news_page.dart';
import 'package:acter/features/news/pages/simple_post.dart';
import 'package:acter/features/onboarding/pages/intro_page.dart';
import 'package:acter/features/onboarding/pages/intro_profile.dart';
import 'package:acter/features/onboarding/pages/login_page.dart';
import 'package:acter/features/onboarding/pages/register_page.dart';
import 'package:acter/features/onboarding/pages/start_page.dart';
import 'package:acter/features/pins/dialogs/create_pin_sheet.dart';
import 'package:acter/features/pins/pages/pin_page.dart';
import 'package:acter/features/pins/pages/pins_page.dart';
import 'package:acter/features/profile/pages/my_profile_page.dart';
import 'package:acter/features/search/pages/quick_jump.dart';
import 'package:acter/features/search/pages/search.dart';
import 'package:acter/features/settings/pages/index_page.dart';
import 'package:acter/features/settings/pages/info_page.dart';
import 'package:acter/features/settings/pages/labs_page.dart';
import 'package:acter/features/settings/pages/licenses_page.dart';
import 'package:acter/features/space/dialogs/edit_space_sheet.dart';
import 'package:acter/features/space/dialogs/invite_to_space_dialog.dart';
import 'package:acter/features/space/pages/chats_page.dart';
import 'package:acter/features/space/pages/events_page.dart';
import 'package:acter/features/space/pages/overview_page.dart';
import 'package:acter/features/space/pages/pins_page.dart';
import 'package:acter/features/space/pages/related_spaces_page.dart';
import 'package:acter/features/space/pages/shell_page.dart';
import 'package:acter/features/space/providers/space_navbar_provider.dart';
import 'package:acter/features/spaces/dialogs/create_space_sheet.dart';
import 'package:acter/features/spaces/pages/join_space.dart';
import 'package:acter/features/spaces/pages/spaces_page.dart';
import 'package:acter/features/todo/pages/create_task_sidesheet.dart';
import 'package:acter/features/todo/pages/todo_page.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/riverpod.dart';

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
  final next = Uri.encodeComponent(state.uri.toString());

  // ignore: deprecated_member_use
  return state.namedLocation(
    Routes.start.name,
    queryParameters: {'next': next},
  );
}

final GlobalKey<NavigatorState> rootNavKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final GlobalKey<NavigatorState> shellNavKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

final GlobalKey<NavigatorState> spaceNavKey = GlobalKey<NavigatorState>(
  debugLabel: 'space',
);

List<RouteBase> makeRoutes(Ref ref) {
  final tabKeyNotifier = ref.watch(selectedTabKeyProvider.notifier);
  return [
    GoRoute(
      name: Routes.intro.name,
      path: Routes.intro.route,
      builder: (context, state) => const IntroPage(),
    ),
    GoRoute(
      name: Routes.start.name,
      path: Routes.start.route,
      builder: (context, state) => const StartPage(),
    ),
    GoRoute(
      name: Routes.introProfile.name,
      path: Routes.introProfile.route,
      builder: (context, state) => const IntroProfile(),
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
      parentNavigatorKey: rootNavKey,
      name: Routes.bugReport.name,
      path: Routes.bugReport.route,
      pageBuilder: (context, state) => DialogPage(
        builder: (BuildContext ctx) => BugReportPage(
          imagePath: state.uri.queryParameters['screenshot'],
        ),
      ),
    ),
    GoRoute(
      parentNavigatorKey: rootNavKey,
      name: Routes.quickJump.name,
      path: Routes.quickJump.route,
      pageBuilder: (context, state) => DialogPage(
        builder: (BuildContext ctx) => const QuickjumpDialog(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: rootNavKey,
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

    GoRoute(
      parentNavigatorKey: rootNavKey,
      name: Routes.actionAddPin.name,
      path: Routes.actionAddPin.route,
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
          child: CreatePinSheet(
            initialSelectedSpace: state.uri.queryParameters['spaceId'],
          ),
        );
      },
    ),

    GoRoute(
      parentNavigatorKey: rootNavKey,
      name: Routes.createEvent.name,
      path: Routes.createEvent.route,
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
          child: CreateEventSheet(
            initialSelectedSpace: state.uri.queryParameters['spaceId'],
          ),
        );
      },
    ),

    GoRoute(
      parentNavigatorKey: rootNavKey,
      name: Routes.editCalendarEvent.name,
      path: Routes.editCalendarEvent.route,
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
          child: EditEventSheet(calendarId: state.pathParameters['calendarId']),
        );
      },
    ),

    GoRoute(
      parentNavigatorKey: rootNavKey,
      name: Routes.createSpace.name,
      path: Routes.createSpace.route,
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
          child: CreateSpacePage(
            initialParentsSpaceId: state.uri.queryParameters['parentSpaceId'],
          ),
        );
      },
    ),

    GoRoute(
      parentNavigatorKey: rootNavKey,
      name: Routes.actionAddUpdate.name,
      path: Routes.actionAddUpdate.route,
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
          child: const SimpleNewsPost(),
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavKey,
      name: Routes.editSpace.name,
      path: Routes.editSpace.route,
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
          child: EditSpacePage(spaceId: state.uri.queryParameters['spaceId']),
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavKey,
      name: Routes.spaceInvite.name,
      path: Routes.spaceInvite.route,
      pageBuilder: (context, state) => DialogPage(
        builder: (BuildContext ctx) => InviteToSpaceDialog(
          spaceId: state.pathParameters['spaceId']!,
        ),
      ),
    ),

    GoRoute(
      parentNavigatorKey: rootNavKey,
      name: Routes.createChat.name,
      path: Routes.createChat.route,
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
          child: CreateChatSheet(
            initialSelectedSpaceId: state.uri.queryParameters['spaceId'],
          ),
        );
      },
    ),

    /// Application shell
    ShellRoute(
      navigatorKey: shellNavKey,
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
          parentNavigatorKey: shellNavKey,
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
          name: Routes.pins.name,
          path: Routes.pins.route,
          redirect: authGuardRedirect,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              key: state.pageKey,
              child: const PinsPage(),
            );
          },
        ),

        GoRoute(
          name: Routes.pin.name,
          path: Routes.pin.route,
          redirect: authGuardRedirect,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              key: state.pageKey,
              child: PinPage(pinId: state.pathParameters['pinId']!),
            );
          },
        ),

        GoRoute(
          name: Routes.calendarEvent.name,
          path: Routes.calendarEvent.route,
          redirect: authGuardRedirect,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              key: state.pageKey,
              child: CalendarEventPage(
                calendarId: state.pathParameters['calendarId']!,
              ),
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
          name: Routes.chat.name,
          path: Routes.chat.route,
          redirect: authGuardRedirect,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              key: state.pageKey,
              child: const ChatPage(),
            );
          },
        ),

        GoRoute(
          name: Routes.chatroom.name,
          path: Routes.chatroom.route,
          redirect: authGuardRedirect,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              key: state.pageKey,
              child: const RoomPage(),
            );
          },
        ),

        GoRoute(
          name: Routes.chatProfile.name,
          path: Routes.chatProfile.route,
          redirect: authGuardRedirect,
          builder: (context, state) => const RoomProfilePage(),
        ),

        GoRoute(
          name: Routes.dashboard.name,
          path: Routes.dashboard.route,
          redirect: authGuardRedirect,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              key: state.pageKey,
              child: const Dashboard(),
            );
          },
        ),

        // ---- SETTINGS
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

        /// Space subshell
        ShellRoute(
          navigatorKey: spaceNavKey,
          pageBuilder: (context, state, child) {
            return NoTransitionPage(
              key: state.pageKey,
              child: SpaceShell(
                spaceIdOrAlias: state.pathParameters['spaceId']!,
                child: child,
              ),
            );
          },
          routes: <RouteBase>[
            GoRoute(
              name: Routes.spaceRelatedSpaces.name,
              path: Routes.spaceRelatedSpaces.route,
              redirect: authGuardRedirect,
              pageBuilder: (context, state) {
                tabKeyNotifier.switchTo(const Key('spaces'));
                return NoTransitionPage(
                  key: state.pageKey,
                  child: RelatedSpacesPage(
                    spaceIdOrAlias: state.pathParameters['spaceId']!,
                  ),
                );
              },
            ),
            GoRoute(
              name: Routes.spaceMembers.name,
              path: Routes.spaceMembers.route,
              redirect: authGuardRedirect,
              pageBuilder: (context, state) {
                tabKeyNotifier.switchTo(const Key('members'));
                return NoTransitionPage(
                  key: state.pageKey,
                  child: SpaceMembersPage(
                    spaceIdOrAlias: state.pathParameters['spaceId']!,
                  ),
                );
              },
            ),
            GoRoute(
              name: Routes.spacePins.name,
              path: Routes.spacePins.route,
              redirect: authGuardRedirect,
              pageBuilder: (context, state) {
                tabKeyNotifier.switchTo(const Key('pins'));
                return NoTransitionPage(
                  key: state.pageKey,
                  child: SpacePinsPage(
                    spaceIdOrAlias: state.pathParameters['spaceId']!,
                  ),
                );
              },
            ),
            GoRoute(
              name: Routes.spaceEvents.name,
              path: Routes.spaceEvents.route,
              redirect: authGuardRedirect,
              pageBuilder: (context, state) {
                tabKeyNotifier.switchTo(const Key('events'));
                return NoTransitionPage(
                  key: state.pageKey,
                  child: SpaceEventsPage(
                    spaceIdOrAlias: state.pathParameters['spaceId']!,
                  ),
                );
              },
            ),
            GoRoute(
              name: Routes.spaceChats.name,
              path: Routes.spaceChats.route,
              redirect: authGuardRedirect,
              pageBuilder: (context, state) {
                tabKeyNotifier.switchTo(const Key('chat'));
                return NoTransitionPage(
                  key: state.pageKey,
                  child: SpaceChatsPage(
                    spaceIdOrAlias: state.pathParameters['spaceId']!,
                  ),
                );
              },
            ),
            GoRoute(
              name: Routes.space.name,
              path: Routes.space.route,
              redirect: authGuardRedirect,
              pageBuilder: (context, state) {
                tabKeyNotifier.switchTo(const Key('overview'));
                return NoTransitionPage(
                  key: state.pageKey,
                  child: SpaceOverview(
                    spaceIdOrAlias: state.pathParameters['spaceId']!,
                  ),
                );
              },
            ),
          ],
        ),

        GoRoute(
          name: Routes.joinSpace.name,
          path: Routes.joinSpace.route,
          redirect: authGuardRedirect,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              key: state.pageKey,
              child: const JoinSpacePage(),
            );
          },
        ),

        GoRoute(
          name: Routes.spaces.name,
          path: Routes.spaces.route,
          redirect: authGuardRedirect,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              key: state.pageKey,
              child: const SpacesPage(),
            );
          },
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
            if (context.mounted && isDesktop(context)) {
              return Routes.dashboard.route;
            } else {
              return Routes.updates.route;
            }
          },
        ),
      ],
    ),
  ];
}
