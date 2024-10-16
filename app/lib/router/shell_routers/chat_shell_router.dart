import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/pages/room_page.dart';
import 'package:acter/features/chat/pages/room_profile_page.dart';
import 'package:acter/features/chat/widgets/chat_layout_builder.dart';
import 'package:acter/features/chat_ng/widgets/rooms_list.dart';
import 'package:acter/features/invite_members/pages/invite_page.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:acter/features/space/settings/pages/visibility_accessibility_page.dart';
import 'package:acter/router/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// define the chat layout builder depending on whether the user has set
/// the chat-ng feature.
Widget _chatLayoutBuilder({Widget? centerChild, Widget? expandedChild}) {
  final isChatNg =
      rootNavKey.currentContext?.read(isActiveProvider(LabsFeature.chatNG)) ==
          true;
  return isChatNg
      ? ChatLayoutBuilder(
          roomListWidgetBuilder: (s) => RoomsListNGWidget(onSelected: s),
          centerChild: centerChild,
          expandedChild: expandedChild,
        )
      : ChatLayoutBuilder(
          centerChild: centerChild,
          expandedChild: expandedChild,
        );
}

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
        child: _chatLayoutBuilder(),
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
        child: _chatLayoutBuilder(
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
        child: _chatLayoutBuilder(
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
        child: _chatLayoutBuilder(
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
    name: Routes.chatInvite.name,
    path: Routes.chatInvite.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final roomId = state.pathParameters['roomId']!;
      return NoTransitionPage(
        key: state.pageKey,
        child: _chatLayoutBuilder(
          centerChild: RoomPage(
            roomId: roomId,
          ),
          expandedChild: InvitePage(
            roomId: roomId,
          ),
        ),
      );
    },
  ),
];
