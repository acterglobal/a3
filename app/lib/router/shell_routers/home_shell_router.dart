import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/categories/organize_categories_page.dart';
import 'package:acter/features/categories/utils/category_utils.dart';
import 'package:acter/features/chat/pages/sub_chats_page.dart';
import 'package:acter/features/events/pages/create_event_page.dart';
import 'package:acter/features/events/pages/event_details_page.dart';
import 'package:acter/features/events/pages/event_list_page.dart';
import 'package:acter/features/home/pages/dashboard.dart';
import 'package:acter/features/invite_members/pages/invite_individual_users.dart';
import 'package:acter/features/invite_members/pages/invite_page.dart';
import 'package:acter/features/invite_members/pages/invite_pending.dart';
import 'package:acter/features/invite_members/pages/invite_space_members.dart';
import 'package:acter/features/invite_members/pages/share_invite_code.dart';
import 'package:acter/features/news/pages/news_list_page.dart';
import 'package:acter/features/pins/pages/pin_details_page.dart';
import 'package:acter/features/pins/pages/pins_list_page.dart';
import 'package:acter/features/profile/pages/my_profile_page.dart';
import 'package:acter/features/public_room_search/pages/search_public_directory.dart';
import 'package:acter/features/settings/pages/backup_page.dart';
import 'package:acter/features/settings/pages/blocked_users.dart';
import 'package:acter/features/settings/pages/change_password.dart';
import 'package:acter/features/settings/pages/chat_settings_page.dart';
import 'package:acter/features/settings/pages/email_addresses.dart';
import 'package:acter/features/settings/pages/info_page.dart';
import 'package:acter/features/settings/pages/labs_page.dart';
import 'package:acter/features/settings/pages/language_select_page.dart';
import 'package:acter/features/settings/pages/licenses_page.dart';
import 'package:acter/features/notifications/pages/notifications_page.dart';
import 'package:acter/features/settings/pages/sessions_page.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:acter/features/space/pages/members_page.dart';
import 'package:acter/features/space/pages/space_details_page.dart';
import 'package:acter/features/space/settings/pages/apps_settings_page.dart';
import 'package:acter/features/space/settings/pages/index_page.dart';
import 'package:acter/features/space/settings/pages/notification_configuration_page.dart';
import 'package:acter/features/space/settings/pages/visibility_accessibility_page.dart';
import 'package:acter/features/space/settings/widgets/space_settings_menu.dart';
import 'package:acter/features/spaces/pages/create_space_page.dart';
import 'package:acter/features/spaces/pages/space_list_page.dart';
import 'package:acter/features/spaces/pages/sub_spaces_page.dart';
import 'package:acter/features/super_invites/pages/super_invites.dart';
import 'package:acter/features/tasks/pages/task_item_detail_page.dart';
import 'package:acter/features/tasks/pages/task_list_details_page.dart';
import 'package:acter/features/tasks/pages/tasks_list_page.dart';
import 'package:acter/router/router.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final homeShellRoutes = [
  GoRoute(
    name: Routes.dashboard.name,
    path: Routes.dashboard.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      return MaterialPage(
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
      return MaterialPage(
        key: state.pageKey,
        child: const SettingsPage(isFullPage: true),
      );
    },
  ),
  GoRoute(
    name: Routes.licenses.name,
    path: Routes.licenses.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      return MaterialPage(
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
      return MaterialPage(
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
      return MaterialPage(
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
      return MaterialPage(
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
      return MaterialPage(
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
      return MaterialPage(
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
      return MaterialPage(
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
      return MaterialPage(
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
      return MaterialPage(
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
      return MaterialPage(
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
      return MaterialPage(
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
      return MaterialPage(
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
      return MaterialPage(
        key: state.pageKey,
        child: const ChangePasswordPage(),
      );
    },
  ),
  GoRoute(
    name: Routes.subSpaces.name,
    path: Routes.subSpaces.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final spaceId = state.pathParameters['spaceId']
          .expect('subSpaces route needs spaceId as path param');
      return MaterialPage(
        key: state.pageKey,
        child: SubSpacesPage(spaceId: spaceId),
      );
    },
  ),
  GoRoute(
    name: Routes.subChats.name,
    path: Routes.subChats.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final spaceId = state.pathParameters['spaceId']
          .expect('subChats route needs spaceId as path param');
      return MaterialPage(
        key: state.pageKey,
        child: SubChatsPage(spaceId: spaceId),
      );
    },
  ),
  GoRoute(
    name: Routes.organizeCategories.name,
    path: Routes.organizeCategories.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final spaceId = state.pathParameters['spaceId']
          .expect('organizeCategories route needs spaceId as path param');
      final categoriesFor = state.pathParameters['categoriesFor']
          .expect('organizeCategories route needs categoriesFor as path param');
      return MaterialPage(
        key: state.pageKey,
        child: OrganizeCategoriesPage(
          spaceId: spaceId,
          categoriesFor: CategoryUtils().getCategoryEnumFromName(categoriesFor),
        ),
      );
    },
  ),
  GoRoute(
    name: Routes.spaceMembers.name,
    path: Routes.spaceMembers.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final spaceId = state.pathParameters['spaceId']
          .expect('spaceMembers route needs spaceId as path param');
      return MaterialPage(
        key: state.pageKey,
        child: SpaceMembersPage(spaceIdOrAlias: spaceId),
      );
    },
  ),
  GoRoute(
    name: Routes.spacePins.name,
    path: Routes.spacePins.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final spaceId = state.pathParameters['spaceId']
          .expect('spacePins route needs spaceId as path param');
      return MaterialPage(
        key: state.pageKey,
        child: PinsListPage(spaceId: spaceId),
      );
    },
  ),
  GoRoute(
    name: Routes.spaceEvents.name,
    path: Routes.spaceEvents.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final spaceId = state.pathParameters['spaceId']
          .expect('spaceEvents route needs spaceId as path param');
      return MaterialPage(
        key: state.pageKey,
        child: EventListPage(spaceId: spaceId),
      );
    },
  ),
  GoRoute(
    name: Routes.spaceTasks.name,
    path: Routes.spaceTasks.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final spaceId = state.pathParameters['spaceId']
          .expect('spaceTasks route needs spaceId as path param');
      return MaterialPage(
        key: state.pageKey,
        child: TasksListPage(spaceId: spaceId),
      );
    },
  ),
  GoRoute(
    name: Routes.spaceUpdates.name,
    path: Routes.spaceUpdates.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final spaceId = state.pathParameters['spaceId']
          .expect('spaceUpdates route needs spaceId as path param');
      return MaterialPage(
        key: state.pageKey,
        child: NewsListPage(spaceId: spaceId),
      );
    },
  ),
  GoRoute(
    name: Routes.searchPublicDirectory.name,
    path: Routes.searchPublicDirectory.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final query = state.uri.queryParameters['query'];
      return MaterialPage(
        key: state.pageKey,
        child: SearchPublicDirectory(query: query),
      );
    },
  ),
  GoRoute(
    name: Routes.space.name,
    path: Routes.space.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final spaceId = state.pathParameters['spaceId']
          .expect('space route needs spaceId as path param');
      return MaterialPage(
        key: state.pageKey,
        child: SpaceDetailsPage(spaceId: spaceId),
      );
    },
  ),
  GoRoute(
    name: Routes.spaces.name,
    path: Routes.spaces.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final searchQuery = state.uri.queryParameters['searchQuery'];
      return MaterialPage(
        key: state.pageKey,
        child: SpaceListPage(searchQuery: searchQuery),
      );
    },
  ),
  // ---- Space SETTINGS
  GoRoute(
    name: Routes.spaceSettings.name,
    path: Routes.spaceSettings.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final spaceId = state.pathParameters['spaceId']
          .expect('spaceSettings route needs spaceId as path param');
      return MaterialPage(
        key: state.pageKey,
        child: SpaceSettingsMenuIndexPage(spaceId: spaceId),
      );
    },
  ),
  GoRoute(
    name: Routes.spaceSettingsApps.name,
    path: Routes.spaceSettingsApps.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final spaceId = state.pathParameters['spaceId']
          .expect('spaceSettingsApps route needs spaceId as path param');
      return MaterialPage(
        key: state.pageKey,
        child: SpaceAppsSettingsPage(spaceId: spaceId),
      );
    },
  ),
  GoRoute(
    name: Routes.spaceSettingsVisibility.name,
    path: Routes.spaceSettingsVisibility.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final spaceId = state.pathParameters['spaceId']
          .expect('spaceSettingsVisibility route needs spaceId as path param');
      return MaterialPage(
        key: state.pageKey,
        child: WithSidebar(
          sidebar: SpaceSettingsMenu(spaceId: spaceId),
          child: VisibilityAccessibilityPage(roomId: spaceId),
        ),
      );
    },
  ),
  GoRoute(
    name: Routes.spaceSettingsNotifications.name,
    path: Routes.spaceSettingsNotifications.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final spaceId = state.pathParameters['spaceId'].expect(
        'spaceSettingsNotifications route needs spaceId as path param',
      );
      return MaterialPage(
        key: state.pageKey,
        child: SpaceNotificationConfigurationPage(spaceId: spaceId),
      );
    },
  ),
  GoRoute(
    name: Routes.tasks.name,
    path: Routes.tasks.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final searchQuery = state.uri.queryParameters['searchQuery'];
      return MaterialPage(
        key: state.pageKey,
        child: TasksListPage(searchQuery: searchQuery),
      );
    },
  ),
  GoRoute(
    name: Routes.taskItemDetails.name,
    path: Routes.taskItemDetails.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final taskListId = state.pathParameters['taskListId']
          .expect('taskItemDetails route needs taskListId as path param');
      final taskId = state.pathParameters['taskId']
          .expect('taskItemDetails route needs taskId as path param');
      return MaterialPage(
        key: state.pageKey,
        child: TaskItemDetailPage(
          taskListId: taskListId,
          taskId: taskId,
        ),
      );
    },
  ),
  GoRoute(
    name: Routes.taskListDetails.name,
    path: Routes.taskListDetails.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final taskListId = state.pathParameters['taskListId']
          .expect('taskListDetails route needs taskListId as path param');
      return MaterialPage(
        key: state.pageKey,
        child: TaskListDetailPage(taskListId: taskListId),
      );
    },
  ),
  GoRoute(
    name: Routes.pins.name,
    path: Routes.pins.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final searchQuery = state.uri.queryParameters['searchQuery'];
      return MaterialPage(
        key: state.pageKey,
        child: PinsListPage(searchQuery: searchQuery),
      );
    },
  ),
  GoRoute(
    name: Routes.pin.name,
    path: Routes.pin.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final pinId = state.pathParameters['pinId']
          .expect('pin route needs pinId as path param');
      return MaterialPage(
        key: state.pageKey,
        child: PinDetailsPage(pinId: pinId),
      );
    },
  ),
  GoRoute(
    name: Routes.calendarEvents.name,
    path: Routes.calendarEvents.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final searchQuery = state.uri.queryParameters['searchQuery'];
      return MaterialPage(
        key: state.pageKey,
        child: EventListPage(searchQuery: searchQuery),
      );
    },
  ),
  GoRoute(
    name: Routes.createEvent.name,
    path: Routes.createEvent.route,
    pageBuilder: (context, state) {
      final extra = state.extra;
      CalendarEvent? templateEvent;
      if (extra != null && extra is CalendarEvent) {
        templateEvent = extra;
      }
      final String? spaceId = state.uri.queryParameters['spaceId'];
      return MaterialPage(
        key: state.pageKey,
        child: CreateEventPage(
          initialSelectedSpace: spaceId?.isNotEmpty == true ? spaceId : null,
          templateEvent: templateEvent,
        ),
      );
    },
  ),
  GoRoute(
    name: Routes.calendarEvent.name,
    path: Routes.calendarEvent.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final calendarId = state.pathParameters['calendarId']
          .expect('calendarEvent route needs calendarId as path param');
      return MaterialPage(
        key: state.pageKey,
        child: EventDetailPage(calendarId: calendarId),
      );
    },
  ),

  GoRoute(
    name: Routes.updateList.name,
    path: Routes.updateList.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      return MaterialPage(
        key: state.pageKey,
        child: const NewsListPage(),
      );
    },
  ),
  GoRoute(
    name: Routes.createSpace.name,
    path: Routes.createSpace.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final parentSpaceId = state.uri.queryParameters['parentSpaceId'];
      return MaterialPage(
        key: state.pageKey,
        child: CreateSpacePage(initialParentsSpaceId: parentSpaceId),
      );
    },
  ),
  GoRoute(
    name: Routes.spaceInvite.name,
    path: Routes.spaceInvite.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final spaceId = state.pathParameters['spaceId']
          .expect('spaceInvite route needs spaceId as path param');
      return MaterialPage(
        key: state.pageKey,
        child: InvitePage(roomId: spaceId),
      );
    },
  ),
  GoRoute(
    name: Routes.inviteIndividual.name,
    path: Routes.inviteIndividual.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final roomId = state.uri.queryParameters['roomId']
          .expect('inviteIndividual route needs roomId as query param');
      return MaterialPage(
        key: state.pageKey,
        child: InviteIndividualUsers(roomId: roomId),
      );
    },
  ),
  GoRoute(
    name: Routes.inviteSpaceMembers.name,
    path: Routes.inviteSpaceMembers.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final roomId = state.uri.queryParameters['roomId']
          .expect('inviteSpaceMembers route needs roomId as query param');
      return MaterialPage(
        key: state.pageKey,
        child: InviteSpaceMembers(roomId: roomId),
      );
    },
  ),
  GoRoute(
    name: Routes.shareInviteCode.name,
    path: Routes.shareInviteCode.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final inviteCode = state.uri.queryParameters['inviteCode']
          .expect('shareInviteCode route needs inviteCode as query param');
      final roomId = state.uri.queryParameters['roomId']
          .expect('shareInviteCode route needs roomId as query param');
      return MaterialPage(
        key: state.pageKey,
        child: ShareInviteCode(
          inviteCode: inviteCode,
          roomId: roomId,
        ),
      );
    },
  ),
  GoRoute(
    name: Routes.invitePending.name,
    path: Routes.invitePending.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final roomId = state.uri.queryParameters['roomId']
          .expect('invitePending route needs roomId as query param');
      return MaterialPage(
        key: state.pageKey,
        child: InvitePending(roomId: roomId),
      );
    },
  ),
];
