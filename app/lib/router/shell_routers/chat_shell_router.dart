import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/config/setup.dart';
import 'package:acter/features/chat/pages/room_page.dart';
import 'package:acter/features/chat/pages/room_profile_page.dart';
import 'package:acter/features/chat/widgets/chat_layout_builder.dart';
import 'package:acter/features/chat_ng/pages/chat_room.dart';
import 'package:acter/features/chat_ng/layout/chat_ng_layout_builder.dart';
import 'package:acter/features/chat_ui_showcase/pages/chat_list_showcase_page.dart';
import 'package:acter/features/chat_ui_showcase/pages/chat_room_showcase_page.dart';
import 'package:acter/features/invite_members/pages/invite_page.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:acter/features/space/settings/pages/visibility_accessibility_page.dart';
import 'package:acter/router/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum SubPage { chatProfile, chatSettingsVisibility, chatInvite }

Page<dynamic> _chatPageBuilder({
  required BuildContext context,
  required GoRouterState state,
  SubPage? subPage,
}) {
  // update the page we are routing to
  final roomId = state.pathParameters['roomId'];
  mainProviderContainer.read(selectedChatIdProvider.notifier).select(roomId);

  Widget? expandedChild;

  // still shared:
  if (roomId != null) {
    expandedChild = switch (subPage) {
      SubPage.chatProfile => RoomProfilePage(roomId: roomId),
      SubPage.chatSettingsVisibility => VisibilityAccessibilityPage(
        roomId: roomId,
        impliedClose: true,
      ),
      SubPage.chatInvite => InvitePage(roomId: roomId),
      _ => null,
    };
  }

  final isChatNg =
      mainProviderContainer.read(isActiveProvider(LabsFeature.chatNG)) == true;

  if (isChatNg) {
    final centerChild = roomId != null ? ChatRoomNgPage(roomId: roomId) : null;
    return defaultPageBuilder(
      context: context,
      state: state,
      child: ChatNgLayoutBuilder(
        centerChild: centerChild,
        expandedChild: expandedChild,
      ),
    );
  }

  final centerChild = roomId != null ? RoomPage(roomId: roomId) : null;

  return defaultPageBuilder(
    context: context,
    state: state,
    child: ChatLayoutBuilder(
      centerChild: centerChild,
      expandedChild: expandedChild,
    ),
  );
}

final chatShellRoutes = [
  if (includeChatShowcase) ...[
    GoRoute(
      name: Routes.chatListShowcase.name,
      path: Routes.chatListShowcase.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        return MaterialPage(key: state.pageKey, child: ChatListShowcasePage());
      },
    ),
    GoRoute(
      name: Routes.chatRoomShowcase.name,
      path: Routes.chatRoomShowcase.route,
      redirect: authGuardRedirect,
      pageBuilder: (context, state) {
        final roomId = state.pathParameters['roomId'];
        return MaterialPage(
          key: state.pageKey,
          child: ChatRoomShowcasePage(roomId: roomId ?? ''),
        );
      },
    ),
  ],
  GoRoute(
    name: Routes.chat.name,
    path: Routes.chat.route,
    redirect: authGuardRedirect,
    pageBuilder:
        (context, state) => _chatPageBuilder(context: context, state: state),
  ),
  GoRoute(
    name: Routes.chatroom.name,
    path: Routes.chatroom.route,
    redirect: authGuardRedirect,
    pageBuilder:
        (context, state) => _chatPageBuilder(context: context, state: state),
  ),
  GoRoute(
    name: Routes.chatProfile.name,
    path: Routes.chatProfile.route,
    redirect: authGuardRedirect,
    pageBuilder:
        (context, state) => _chatPageBuilder(
          context: context,
          state: state,
          subPage: SubPage.chatProfile,
        ),
  ),
  GoRoute(
    name: Routes.chatSettingsVisibility.name,
    path: Routes.chatSettingsVisibility.route,
    redirect: authGuardRedirect,
    pageBuilder:
        (context, state) => _chatPageBuilder(
          context: context,
          state: state,
          subPage: SubPage.chatSettingsVisibility,
        ),
  ),
  GoRoute(
    name: Routes.chatInvite.name,
    path: Routes.chatInvite.route,
    redirect: authGuardRedirect,
    pageBuilder:
        (context, state) => _chatPageBuilder(
          context: context,
          state: state,
          subPage: SubPage.chatInvite,
        ),
  ),
];
