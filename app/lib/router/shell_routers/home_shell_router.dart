import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/invite_members/pages/invite_indicidual_users.dart';
import 'package:acter/features/invite_members/pages/invite_page.dart';
import 'package:acter/features/events/pages/create_edit_event_page.dart';
import 'package:acter/features/events/pages/events_page.dart';
import 'package:acter/features/events/pages/event_details_page.dart';
import 'package:acter/features/home/pages/dashboard.dart';
import 'package:acter/features/invite_members/pages/invite_pending.dart';
import 'package:acter/features/invite_members/pages/invite_space_members.dart';
import 'package:acter/features/invite_members/pages/share_invite_code.dart';
import 'package:acter/features/pins/pages/pin_page.dart';
import 'package:acter/features/pins/pages/pins_page.dart';
import 'package:acter/features/settings/pages/backup_page.dart';
import 'package:acter/features/settings/pages/change_password.dart';
import 'package:acter/features/settings/pages/chat_settings_page.dart';
import 'package:acter/features/settings/pages/language_select_page.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:acter/features/profile/pages/my_profile_page.dart';
import 'package:acter/features/settings/pages/blocked_users.dart';
import 'package:acter/features/settings/pages/email_addresses.dart';
import 'package:acter/features/settings/pages/info_page.dart';
import 'package:acter/features/settings/pages/labs_page.dart';
import 'package:acter/features/settings/pages/licenses_page.dart';
import 'package:acter/features/settings/pages/notifications_page.dart';
import 'package:acter/features/settings/pages/sessions_page.dart';
import 'package:acter/features/space/settings/pages/visibility_accessibility_page.dart';
import 'package:acter/features/super_invites/pages/super_invites.dart';
import 'package:acter/features/space/pages/chats_page.dart';
import 'package:acter/features/space/pages/events_page.dart';
import 'package:acter/features/space/pages/members_page.dart';
import 'package:acter/features/space/pages/overview_page.dart';
import 'package:acter/features/space/pages/pins_page.dart';
import 'package:acter/features/space/pages/sub_spaces_page.dart';
import 'package:acter/features/space/pages/space_tasks_page.dart';
import 'package:acter/features/space/providers/space_navbar_provider.dart';
import 'package:acter/features/space/settings/pages/apps_settings_page.dart';
import 'package:acter/features/space/settings/pages/index_page.dart';
import 'package:acter/features/space/settings/pages/notification_configuration_page.dart';
import 'package:acter/features/public_room_search/pages/search_public_directory.dart';
import 'package:acter/features/spaces/pages/create_space_page.dart';
import 'package:acter/features/spaces/pages/spaces_page.dart';
import 'package:acter/features/tasks/pages/task_item_detail_page.dart';
import 'package:acter/features/tasks/pages/task_list_details_page.dart';
import 'package:acter/features/tasks/pages/tasks_page.dart';
import 'package:acter/router/router.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> makeHomeShellRoutes(ref) {
  final tabKeyNotifier = ref.watch(selectedTabKeyProvider.notifier);
  return <RouteBase>[
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
          child: const SettingsPage(),
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
      name: Routes.settingsChat.name,
      path: Routes.settingsChat.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: const ChatSettingsPage(),
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
      name: Routes.settingsSuperInvites.name,
      path: Routes.settingsSuperInvites.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: const SuperInvitesPage(),
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
    GoRoute(
      name: Routes.myProfile.name,
      path: Routes.myProfile.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: const MyProfilePage(),
        );
      },
    ),
    GoRoute(
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
      name: Routes.settingBackup.name,
      path: Routes.settingBackup.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: const BackupPage(),
        );
      },
    ),
    GoRoute(
      name: Routes.settingLanguage.name,
      path: Routes.settingLanguage.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: const LanguageSelectPage(),
        );
      },
    ),
    GoRoute(
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
      name: Routes.changePassword.name,
      path: Routes.changePassword.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: const ChangePasswordPage(),
        );
      },
    ),
    GoRoute(
      name: Routes.spaceRelatedSpaces.name,
      path: Routes.spaceRelatedSpaces.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        tabKeyNotifier.switchTo(const Key('spaces'));
        return NoTransitionPage(
          key: state.pageKey,
          child: SubSpacesPage(
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
      name: Routes.spaceTasks.name,
      path: Routes.spaceTasks.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        tabKeyNotifier.switchTo(const Key('tasks'));
        return NoTransitionPage(
          key: state.pageKey,
          child: SpaceTasksPage(
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
    GoRoute(
      name: Routes.searchPublicDirectory.name,
      path: Routes.searchPublicDirectory.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: SearchPublicDirectory(
            query: state.uri.queryParameters['query'],
          ),
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
    // ---- Space SETTINGS
    GoRoute(
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
    GoRoute(
      name: Routes.spaceSettingsVisibility.name,
      path: Routes.spaceSettingsVisibility.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: VisibilityAccessibilityPage(
            roomId: state.pathParameters['spaceId']!,
          ),
        );
      },
    ),
    GoRoute(
      name: Routes.spaceSettingsNotifications.name,
      path: Routes.spaceSettingsNotifications.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: SpaceNotificationConfigurationPage(
            spaceId: state.pathParameters['spaceId']!,
          ),
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
          child: TasksPage(),
        );
      },
    ),
    GoRoute(
      name: Routes.taskItemDetails.name,
      path: Routes.taskItemDetails.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: TaskItemDetailPage(
            taskListId: state.pathParameters['taskListId']!,
            taskId: state.pathParameters['taskId']!,
          ),
        );
      },
    ),
    GoRoute(
      name: Routes.taskListDetails.name,
      path: Routes.taskListDetails.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: TaskListDetailPage(
            taskListId: state.pathParameters['taskListId']!,
          ),
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
      name: Routes.createEvent.name,
      path: Routes.createEvent.route,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: CreateEditEventPage(
            initialSelectedSpace: state.uri.queryParameters['spaceId'],
          ),
        );
      },
    ),
    GoRoute(
      name: Routes.editCalendarEvent.name,
      path: Routes.editCalendarEvent.route,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: CreateEditEventPage(
            calendarId: state.pathParameters['calendarId'],
          ),
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
          child: EventDetailPage(
            calendarId: state.pathParameters['calendarId']!,
          ),
        );
      },
    ),
    GoRoute(
      name: Routes.createSpace.name,
      path: Routes.createSpace.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: CreateSpacePage(
            initialParentsSpaceId: state.uri.queryParameters['parentSpaceId'],
          ),
        );
      },
    ),
    GoRoute(
      name: Routes.spaceInvite.name,
      path: Routes.spaceInvite.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: InvitePage(
            roomId: state.pathParameters['spaceId']!,
          ),
        );
      },
    ),
    GoRoute(
      name: Routes.inviteIndividual.name,
      path: Routes.inviteIndividual.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: InviteIndividualUsers(
            roomId: state.uri.queryParameters['roomId']!,
          ),
        );
      },
    ),
    GoRoute(
      name: Routes.inviteSpaceMembers.name,
      path: Routes.inviteSpaceMembers.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: InviteSpaceMembers(
            roomId: state.uri.queryParameters['roomId']!,
          ),
        );
      },
    ),
    GoRoute(
      name: Routes.shareInviteCode.name,
      path: Routes.shareInviteCode.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: ShareInviteCode(
            inviteCode: state.uri.queryParameters['inviteCode']!,
            roomId: state.uri.queryParameters['roomId']!,
          ),
        );
      },
    ),
    GoRoute(
      name: Routes.invitePending.name,
      path: Routes.invitePending.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        return NoTransitionPage(
          key: state.pageKey,
          child: InvitePending(
            roomId: state.uri.queryParameters['roomId']!,
          ),
        );
      },
    ),
  ];
}
