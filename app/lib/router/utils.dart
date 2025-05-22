import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/router/routes.dart';
import 'package:acter/features/main/app_shell.dart';
import 'package:acter/config/setup.dart';
import 'package:acter/router/providers/router_providers.dart';
import 'package:acter/router/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum ShellBranch {
  homeShell,
  updatesShell,
  chatsShell,
  activitiesShell,
  searchShell;

  GlobalKey<NavigatorState> get key => switch (this) {
    ShellBranch.homeShell => homeTabNavKey,
    ShellBranch.updatesShell => updateTabNavKey,
    ShellBranch.chatsShell => chatTabNavKey,
    ShellBranch.activitiesShell => activitiesTabNavKey,
    ShellBranch.searchShell => searchTabNavKey,
  };
}

/// Make sure we are on the right navigation branch
/// this needs to be run _before_ you `go` or `push` the route
/// or we only switch in the UI and no really in the active shell
bool navigateOnRightBranch(
  BuildContext context,
  ShellBranch targetBranch,
  void Function(BuildContext) navigationCallback, {
  bool initialLocation = true,
}) {
  final navState =
      (appShellKey.currentContext?.widget as AppShell).navigationShell;
  if (navState.currentIndex != targetBranch.index) {
    // when routed to chat, we always want to jump to the chat
    // tab
    navState.goBranch(targetBranch.index, initialLocation: initialLocation);
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      // We need the UI branch to actually switch first
      // and on first switching to it, it might even need to create the
      // BuildContext, thus we can’t optimized based on that either :(
      navigationCallback(targetBranch.key.currentContext ?? context);
    });
    return true;
  }
  navigationCallback(context);
  return false;
}

final chatRoomUriMatcher = RegExp('/chat/.+');

/// helper to figure out how to route to the specific chat room
void goToChat(BuildContext localContext, String roomId) {
  final currentUri = mainProviderContainer.read(currentRoutingLocation);
  if (!currentUri.startsWith(chatRoomUriMatcher)) {
    // we are not in a chat room. just a regular push routing
    // will do
    navigateOnRightBranch(
      localContext,
      ShellBranch.chatsShell,
      (navContext) => navContext.pushNamed(
        Routes.chatroom.name,
        pathParameters: {'roomId': roomId},
      ),
    );
    return;
  }

  // we are in a chat page
  if (roomId == mainProviderContainer.read(selectedChatIdProvider)) {
    // we are on the same page, nothing to be done
    return;
  }

  // we are on a different chat page. Push replace the current screen
  (rootNavKey.currentContext ?? localContext).pushReplacementNamed(
    Routes.chatroom.name,
    pathParameters: {'roomId': roomId},
  );
}

/// helper to figure out how to route to the specific chat room
void goToSpace(BuildContext localContext, String spaceId) {
  navigateOnRightBranch(
    localContext,
    ShellBranch.homeShell,
    (navContext) => navContext.pushNamed(
      Routes.space.name,
      pathParameters: {'spaceId': spaceId},
    ),
  );
}
