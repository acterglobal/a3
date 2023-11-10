import 'package:acter/common/notifications/notifications.dart';
import 'package:acter/common/pages/fatal_fail.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/dialog_page.dart';
import 'package:acter/common/widgets/side_sheet_page.dart';
import 'package:acter/common/dialogs/invite_to_room_dialog.dart';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/activities/pages/activities_page.dart';
import 'package:acter/features/chat/widgets/create_chat.dart';
import 'package:acter/features/events/pages/events_page.dart';
import 'package:acter/features/events/sheets/create_event_sheet.dart';
import 'package:acter/features/events/sheets/edit_event_sheet.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/pins/sheets/create_pin_sheet.dart';
import 'package:acter/features/pins/sheets/edit_pin_sheet.dart';
import 'package:acter/features/settings/pages/blocked_users.dart';
import 'package:acter/features/settings/pages/notifications_page.dart';
import 'package:acter/features/settings/pages/sessions_page.dart';
import 'package:acter/features/bug_report/pages/bug_report_page.dart';
import 'package:acter/features/chat/pages/chat_select_page.dart';
import 'package:acter/features/chat/pages/chats_shell.dart';
import 'package:acter/features/chat/pages/room_page.dart';
import 'package:acter/features/chat/pages/room_profile_page.dart';
import 'package:acter/features/events/pages/event_page.dart';
import 'package:acter/features/home/pages/dashboard.dart';
import 'package:acter/features/home/pages/home_shell.dart';
import 'package:acter/features/news/pages/news_page.dart';
import 'package:acter/features/news/pages/simple_post.dart';
import 'package:acter/features/onboarding/pages/intro_page.dart';
import 'package:acter/features/onboarding/pages/intro_profile.dart';
import 'package:acter/features/onboarding/pages/login_page.dart';
import 'package:acter/features/onboarding/pages/register_page.dart';
import 'package:acter/features/onboarding/pages/start_page.dart';
import 'package:acter/features/pins/pages/pin_page.dart';
import 'package:acter/features/pins/pages/pins_page.dart';
import 'package:acter/features/profile/pages/my_profile_page.dart';
import 'package:acter/features/search/pages/quick_jump.dart';
import 'package:acter/features/search/pages/search.dart';
import 'package:acter/features/settings/pages/email_addresses.dart';
import 'package:acter/features/settings/pages/index_page.dart';
import 'package:acter/features/settings/pages/info_page.dart';
import 'package:acter/features/settings/pages/labs_page.dart';
import 'package:acter/features/settings/pages/licenses_page.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter/features/space/pages/chats_page.dart';
import 'package:acter/features/space/pages/events_page.dart';
import 'package:acter/features/space/pages/members_page.dart';
import 'package:acter/features/space/pages/overview_page.dart';
import 'package:acter/features/space/pages/pins_page.dart';
import 'package:acter/features/space/pages/related_spaces_page.dart';
import 'package:acter/features/space/pages/tasks_page.dart';
import 'package:acter/features/space/providers/space_navbar_provider.dart';
import 'package:acter/features/space/settings/pages/apps_settings_page.dart';
import 'package:acter/features/space/settings/pages/index_page.dart';
import 'package:acter/features/space/sheets/edit_space_sheet.dart';
import 'package:acter/features/space/sheets/link_room_sheet.dart';
import 'package:acter/features/spaces/pages/join_space.dart';
import 'package:acter/features/spaces/pages/spaces_page.dart';
import 'package:acter/features/spaces/sheets/create_space_sheet.dart';
import 'package:acter/features/tasks/dialogs/create_task_list_sheet.dart';
import 'package:acter/features/tasks/pages/tasks_page.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/riverpod.dart';

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
    // ignore: deprecated_member_use
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
    Routes.start.name,
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
    final deviceId = state.uri.queryParameters['deviceId'];
    final roomId = state.uri.queryParameters['roomId'];
    final client = await acterSdk.getClientWithDeviceId(deviceId!);
    if (await client.hasConvo(roomId!)) {
      // this is a chat
      return state.namedLocation(
        Routes.chatroom.name,
        pathParameters: {'roomId': roomId},
      );
    } else {
      // final eventId = state.uri.queryParameters['eventId'];
      // with the event ID or further information we could figure out the specific action
      return state
          .namedLocation(Routes.space.name, pathParameters: {'roomId': roomId});
    }
  } catch (error, trace) {
    // ignore: deprecated_member_use
    return state.namedLocation(
      Routes.fatalFail.name,
      queryParameters: {'error': error.toString(), 'trace': trace.toString()},
    );
  }
}

final GlobalKey<NavigatorState> rootNavKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final GlobalKey<NavigatorState> shellNavKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

final GlobalKey<NavigatorState> chatShellKey = GlobalKey<NavigatorState>(
  debugLabel: 'chat',
);

List<RouteBase> makeRoutes(Ref ref) {
  final selectedChatNotifier = ref.watch(selectedChatIdProvider.notifier);
  return [
    GoRoute(
      name: Routes.forward.name,
      path: Routes.forward.route,
      redirect: forwardRedirect,
    ),

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
      name: Routes.fatalFail.name,
      path: Routes.fatalFail.route,
      builder: (context, state) => FatalFailPage(
        error: state.uri.queryParameters['error']!,
        trace: state.uri.queryParameters['trace']!,
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
      name: Routes.editPin.name,
      path: Routes.editPin.route,
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
          child: EditPinSheet(pinId: state.pathParameters['pinId']!),
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
      name: Routes.actionAddTaskList.name,
      path: Routes.actionAddTaskList.route,
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
          child: CreateTaskListSheet(
            initialSelectedSpace: state.uri.queryParameters['spaceId'],
          ),
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
      name: Routes.linkChat.name,
      path: Routes.linkChat.route,
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
          child: LinkRoomPage(
            parentSpaceId: state.pathParameters['spaceId']!,
            pageTitle: 'Link as Space-chat',
            childRoomType: ChildRoomType.chat,
          ),
        );
      },
    ),

    GoRoute(
      parentNavigatorKey: rootNavKey,
      name: Routes.linkSubspace.name,
      path: Routes.linkSubspace.route,
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
          child: LinkRoomPage(
            parentSpaceId: state.pathParameters['spaceId']!,
            pageTitle: 'Link Sub-Space',
            childRoomType: ChildRoomType.space,
          ),
        );
      },
    ),

    GoRoute(
      parentNavigatorKey: rootNavKey,
      name: Routes.linkRecommended.name,
      path: Routes.linkRecommended.route,
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
          child: LinkRoomPage(
            parentSpaceId: state.pathParameters['spaceId']!,
            pageTitle: 'Link Recommended-Space',
            childRoomType: ChildRoomType.recommendedSpace,
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
        builder: (BuildContext ctx) => InviteToRoomDialog(
          roomId: state.pathParameters['spaceId']!,
        ),
      ),
    ),
    GoRoute(
      parentNavigatorKey: rootNavKey,
      name: Routes.chatInvite.name,
      path: Routes.chatInvite.route,
      pageBuilder: (context, state) => DialogPage(
        builder: (BuildContext ctx) => InviteToRoomDialog(
          roomId: state.pathParameters['chatId']!,
        ),
      ),
    ),

    GoRoute(
      parentNavigatorKey: rootNavKey,
      name: Routes.createChat.name,
      path: Routes.createChat.route,
      pageBuilder: (context, state) {
        return isLargeScreen(context)
            ? DialogPage(
                barrierDismissible: false,
                builder: (context) => CreateChatPage(
                  initialSelectedSpaceId: state.uri.queryParameters['spaceId'],
                  initialPage: state.extra as int?,
                ),
              )
            : CustomTransitionPage(
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  var begin = const Offset(0.0, 1.0);
                  var end = Offset.zero;
                  var curve = Curves.easeInOut;
                  var tween = Tween(begin: begin, end: end)
                      .chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);
                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
                child: CreateChatPage(
                  initialSelectedSpaceId: state.uri.queryParameters['spaceId'],
                  initialPage: state.extra as int?,
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
          parentNavigatorKey: shellNavKey,
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
            debugPrint('Attempting to ask for push notifications');
            final client = context.read(clientProvider);
            if (client != null) {
              setupPushNotifications(client);
            }
            return true;
          },
        ),
        GoRoute(
          parentNavigatorKey: shellNavKey,
          name: Routes.settingSessions.name,
          path: Routes.settingSessions.route,
          redirect: authGuardRedirect,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              key: state.pageKey,
              child: const SessionsPage(),
            );
          },
        ),
        GoRoute(
          parentNavigatorKey: shellNavKey,
          name: Routes.emailAddresses.name,
          path: Routes.emailAddresses.route,
          redirect: authGuardRedirect,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              key: state.pageKey,
              child: const EmailAddressesPage(),
            );
          },
        ),
        GoRoute(
          parentNavigatorKey: shellNavKey,
          name: Routes.blockedUsers.name,
          path: Routes.blockedUsers.route,
          redirect: authGuardRedirect,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              key: state.pageKey,
              child: const BlockedUsersPage(),
            );
          },
        ),

        GoRoute(
          parentNavigatorKey: shellNavKey,
          name: Routes.tasks.name,
          path: Routes.tasks.route,
          redirect: authGuardRedirect,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              key: state.pageKey,
              child: const TasksPage(),
            );
          },
        ),
        GoRoute(
          parentNavigatorKey: shellNavKey,
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
          parentNavigatorKey: shellNavKey,
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
          parentNavigatorKey: shellNavKey,
          name: Routes.calendarEvents.name,
          path: Routes.calendarEvents.route,
          redirect: authGuardRedirect,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              key: state.pageKey,
              child: const EventsPage(),
            );
          },
        ),

        GoRoute(
          parentNavigatorKey: shellNavKey,
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
          parentNavigatorKey: shellNavKey,
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

        ShellRoute(
          navigatorKey: chatShellKey,
          pageBuilder: (context, state, child) {
            return NoTransitionPage(
              key: state.pageKey,
              child: ChatShell(
                child: child,
              ),
            );
          },
          routes: <RouteBase>[
            GoRoute(
              name: Routes.chat.name,
              path: Routes.chat.route,
              redirect: authGuardRedirect,
              pageBuilder: (context, state) {
                selectedChatNotifier.select(null);
                return NoTransitionPage(
                  key: state.pageKey,
                  child: const ChatSelectPage(),
                );
              },
            ),
            GoRoute(
              name: Routes.chatroom.name,
              path: Routes.chatroom.route,
              redirect: authGuardRedirect,
              pageBuilder: (context, state) {
                final roomId = state.pathParameters['roomId']!;
                selectedChatNotifier.select(roomId);
                return NoTransitionPage(
                  key: state.pageKey,
                  child: RoomPage(roomId: roomId),
                );
              },
            ),
            GoRoute(
              name: Routes.chatProfile.name,
              path: Routes.chatProfile.route,
              redirect: authGuardRedirect,
              pageBuilder: (context, state) {
                final roomId = state.pathParameters['roomId']!;
                selectedChatNotifier.select(roomId);
                return NoTransitionPage(
                  key: state.pageKey,
                  child: RoomProfilePage(roomId: roomId),
                );
              },
            ),
          ],
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
          name: Routes.settingNotifications.name,
          path: Routes.settingNotifications.route,
          redirect: authGuardRedirect,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              key: state.pageKey,
              child: const NotificationsSettingsPage(),
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

        // ---- Space SETTINGS
        GoRoute(
          parentNavigatorKey: shellNavKey,
          name: Routes.spaceSettings.name,
          path: Routes.spaceSettings.route,
          redirect: authGuardRedirect,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              key: state.pageKey,
              child: SpaceSettingsMenuIndexPage(
                spaceId: state.pathParameters['spaceId']!,
              ),
            );
          },
        ),
        GoRoute(
          parentNavigatorKey: shellNavKey,
          name: Routes.spaceSettingsApps.name,
          path: Routes.spaceSettingsApps.route,
          redirect: authGuardRedirect,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              key: state.pageKey,
              child: SpaceAppsSettingsPage(
                spaceId: state.pathParameters['spaceId']!,
              ),
            );
          },
        ),

        /// Space subshell
        GoRoute(
          parentNavigatorKey: shellNavKey,
          name: Routes.spaceRelatedSpaces.name,
          path: Routes.spaceRelatedSpaces.route,
          redirect: authGuardRedirect,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              key: state.pageKey,
              child: RelatedSpacesPage(
                spaceIdOrAlias: state.pathParameters['spaceId']!,
              ),
            );
          },
        ),
        GoRoute(
          parentNavigatorKey: shellNavKey,
          name: Routes.spaceMembers.name,
          path: Routes.spaceMembers.route,
          redirect: authGuardRedirect,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              key: state.pageKey,
              child: SpaceMembersPage(
                spaceIdOrAlias: state.pathParameters['spaceId']!,
              ),
            );
          },
        ),
        GoRoute(
          parentNavigatorKey: shellNavKey,
          name: Routes.spacePins.name,
          path: Routes.spacePins.route,
          redirect: authGuardRedirect,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              key: state.pageKey,
              child: SpacePinsPage(
                spaceIdOrAlias: state.pathParameters['spaceId']!,
              ),
            );
          },
        ),
        GoRoute(
          parentNavigatorKey: shellNavKey,
          name: Routes.spaceEvents.name,
          path: Routes.spaceEvents.route,
          redirect: authGuardRedirect,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              key: state.pageKey,
              child: SpaceEventsPage(
                spaceIdOrAlias: state.pathParameters['spaceId']!,
              ),
            );
          },
        ),
        GoRoute(
          parentNavigatorKey: shellNavKey,
          name: Routes.spaceChats.name,
          path: Routes.spaceChats.route,
          redirect: authGuardRedirect,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              key: state.pageKey,
              child: SpaceChatsPage(
                spaceIdOrAlias: state.pathParameters['spaceId']!,
              ),
            );
          },
        ),
        GoRoute(
          parentNavigatorKey: shellNavKey,
          name: Routes.spaceTasks.name,
          path: Routes.spaceTasks.route,
          redirect: authGuardRedirect,
          pageBuilder: (context, state) {
            ref
                .read(selectedTabKeyProvider.notifier)
                .switchTo(const Key('tasks'));
            return NoTransitionPage(
              key: state.pageKey,
              child: SpaceTasksPage(
                spaceIdOrAlias: state.pathParameters['spaceId']!,
              ),
            );
          },
        ),
        GoRoute(
          parentNavigatorKey: shellNavKey,
          name: Routes.space.name,
          path: Routes.space.route,
          redirect: authGuardRedirect,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              key: state.pageKey,
              child: SpaceOverview(
                spaceIdOrAlias: state.pathParameters['spaceId']!,
              ),
            );
          },
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
            if (context.mounted && isDesktop) {
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
