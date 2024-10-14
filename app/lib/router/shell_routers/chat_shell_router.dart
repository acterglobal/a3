import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/chat-ng/pages/ng_profile_page.dart';
import 'package:acter/features/chat/chat-ng/pages/room_page_ng.dart';
import 'package:acter/features/chat/pages/room_page.dart';
import 'package:acter/features/chat/pages/room_profile_page.dart';
import 'package:acter/features/chat/widgets/chat_layout_builder.dart';
import 'package:acter/features/invite_members/pages/invite_page.dart';
import 'package:acter/features/space/settings/pages/visibility_accessibility_page.dart';
import 'package:acter/router/router.dart';
import 'package:go_router/go_router.dart';

final chatShellRoutes = [
  GoRoute(
    name: Routes.chat.name,
    path: Routes.chat.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      rootNavKey.currentContext
          ?.read(selectedChatIdProvider.notifier)
          .select(null);
      return NoTransitionPage(
        key: state.pageKey,
        child: const ChatLayoutBuilder(),
      );
    },
  ),
  GoRoute(
    name: Routes.chatroom.name,
    path: Routes.chatroom.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final roomId = state.pathParameters['roomId']!;

      rootNavKey.currentContext
          ?.read(selectedChatIdProvider.notifier)
          .select(roomId);
      return NoTransitionPage(
        key: state.pageKey,
        child: ChatLayoutBuilder(
          centerChild: RoomPage(
            roomId: roomId,
          ),
        ),
      );
    },
  ),
  GoRoute(
    name: Routes.chatProfile.name,
    path: Routes.chatProfile.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final roomId = state.pathParameters['roomId']!;
      rootNavKey.currentContext
          ?.read(selectedChatIdProvider.notifier)
          .select(roomId);
      return NoTransitionPage(
        key: state.pageKey,
        child: ChatLayoutBuilder(
          centerChild: RoomPage(
            roomId: roomId,
          ),
          expandedChild: RoomProfilePage(
            roomId: roomId,
          ),
        ),
      );
    },
  ),
  GoRoute(
    name: Routes.chatSettingsVisibility.name,
    path: Routes.chatSettingsVisibility.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final roomId = state.pathParameters['roomId']!;

      rootNavKey.currentContext
          ?.read(selectedChatIdProvider.notifier)
          .select(roomId);
      return NoTransitionPage(
        key: state.pageKey,
        child: ChatLayoutBuilder(
          centerChild: RoomPage(
            roomId: roomId,
          ),
          expandedChild: VisibilityAccessibilityPage(
            roomId: roomId,
            impliedClose: true,
          ),
        ),
      );
    },
  ),
  GoRoute(
    name: Routes.chatNGRoom.name,
    path: Routes.chatNGRoom.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final roomId = state.pathParameters['roomId']!;

      rootNavKey.currentContext
          ?.read(selectedChatIdProvider.notifier)
          .select(roomId);
      return NoTransitionPage(
        key: state.pageKey,
        child: ChatLayoutBuilder(
          centerChild: ChatNGRoomPage(
            roomId: roomId,
          ),
        ),
      );
    },
  ),
  GoRoute(
    name: Routes.chatNGProfile.name,
    path: Routes.chatNGProfile.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final roomId = state.pathParameters['roomId']!;

      rootNavKey.currentContext
          ?.read(selectedChatIdProvider.notifier)
          .select(roomId);
      return NoTransitionPage(
        key: state.pageKey,
        child: ChatLayoutBuilder(
          centerChild: ChatNGRoomPage(roomId: roomId),
          expandedChild: ChatNGProfilePage(
            roomId: roomId,
          ),
        ),
      );
    },
  ),
  GoRoute(
    name: Routes.chatNGSettingsVisibility.name,
    path: Routes.chatNGSettingsVisibility.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final roomId = state.pathParameters['roomId']!;

      rootNavKey.currentContext
          ?.read(selectedChatIdProvider.notifier)
          .select(roomId);
      return NoTransitionPage(
        key: state.pageKey,
        child: ChatLayoutBuilder(
          centerChild: ChatNGRoomPage(
            roomId: roomId,
          ),
          expandedChild: VisibilityAccessibilityPage(
            roomId: roomId,
            impliedClose: true,
          ),
        ),
      );
    },
  ),
  GoRoute(
    name: Routes.chatInvite.name,
    path: Routes.chatInvite.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      return NoTransitionPage(
        key: state.pageKey,
        child: InvitePage(
          roomId: state.pathParameters['roomId']!,
        ),
      );
    },
  ),
];
