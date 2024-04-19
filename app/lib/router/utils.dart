import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum ShellBranchIndex {
  homeShell,
  updatesShell,
  chatsShell,
  activitiesShell,
  quickJumpShell,
}

/// Make sure we are on the right navigation branch
/// this needs to be run _before_ you `go` or `push` the route
/// or we only switch in the UI and no really in the active shell
bool ensureRightBranch(
  BuildContext context,
  int targetBranch, {
  bool initialLocation = false,
}) {
  final navState = StatefulNavigationShell.of(context);
  if (navState.currentIndex != targetBranch) {
    // when routed to chat, we always want to jump to the chat
    // tab
    navState.goBranch(targetBranch, initialLocation: initialLocation);
    return true;
  }
  return false;
}
