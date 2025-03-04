import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/tutorial_dialogs/show_tutorials.dart';
import 'package:acter/common/tutorial_dialogs/space_overview_tutorials/create_or_join_space_tutorials.dart';
import 'package:acter/common/tutorial_dialogs/target_focus.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

// Keys for Sidebar navigation
final sidebarDashboardKey = GlobalKey(debugLabel: 'sidebar-dashboard');
final sidebarUpdateKey = GlobalKey(debugLabel: 'sidebar-update');
final sidebarChatsKey = GlobalKey(debugLabel: 'sidebar-chats');
final sidebarActivityKey = GlobalKey(debugLabel: 'sidebar-activities');
final sidebarJumpToKey = GlobalKey(debugLabel: 'sidebar-jump-to');

// Keys for Bottom navigation
final bottomDashboardKey = GlobalKey(debugLabel: 'bottom-dashboard');
final bottomUpdateKey = GlobalKey(debugLabel: 'bottom-update');
final bottomChatsKey = GlobalKey(debugLabel: 'bottom-chats');
final bottomActivityKey = GlobalKey(debugLabel: 'bottom-activities');
final bottomJumpToKey = GlobalKey(debugLabel: 'bottom-jump-to');

const bottomNavigationPrefKey = 'bottomNavigationPrefKey';

Future<void> setBottomNavigationTutorialsAsViewed() async {
  final prefs = await sharedPrefs();
  if (prefs.getBool(bottomNavigationPrefKey) ?? true) {
    await prefs.setBool(bottomNavigationPrefKey, false);
  }
}

void showCreateOrJoinSpaceTutorials(BuildContext context) {
  if (isDesktop) createOrJoinSpaceTutorials(context: context);
}

void bottomNavigationTutorials({required BuildContext context}) async {
  final lang = L10n.of(context);
  final prefs = await sharedPrefs();
  final isShow = prefs.getBool(bottomNavigationPrefKey) ?? true;

  if (context.mounted && isShow) {
    showTutorials(
      context: context,
      onFinish: () {
        setBottomNavigationTutorialsAsViewed();
        showCreateOrJoinSpaceTutorials(context);
      },
      onClickTarget: (targetFocus) => setBottomNavigationTutorialsAsViewed(),
      onSkip: () {
        setBottomNavigationTutorialsAsViewed();
        showCreateOrJoinSpaceTutorials(context);
        return true;
      },
      targets: [
        targetFocus(
          identify: 'dashboardKey',
          keyTarget: bottomDashboardKey,
          contentAlign: isDesktop ? ContentAlign.right : ContentAlign.top,
          contentImageUrl: 'assets/images/empty_home.svg',
          contentTitle: lang.homeTabTutorialTitle,
          contentDescription: lang.homeTabTutorialDescription,
          isFirst: true,
        ),
        if (!isDesktop)
          targetFocus(
            identify: 'updateKey',
            keyTarget: bottomUpdateKey,
            contentAlign: ContentAlign.top,
            contentImageUrl: 'assets/images/empty_updates.svg',
            contentTitle: lang.updatesTabTutorialTitle,
            contentDescription: lang.updatesTabTutorialDescription,
          ),
        targetFocus(
          identify: 'chatsKey',
          keyTarget: bottomChatsKey,
          contentAlign: isDesktop ? ContentAlign.right : ContentAlign.top,
          contentImageUrl: 'assets/images/empty_chat.svg',
          contentTitle: lang.chatsTabTutorialTitle,
          contentDescription: lang.chatsTabTutorialDescription,
        ),
        targetFocus(
          identify: 'activityKey',
          keyTarget: bottomActivityKey,
          contentAlign: isDesktop ? ContentAlign.right : ContentAlign.top,
          contentImageUrl: 'assets/images/empty_activity.svg',
          contentTitle: lang.activityTabTutorialTitle,
          contentDescription: lang.activityTabTutorialDescription,
        ),
        targetFocus(
          identify: 'jumpToKey',
          keyTarget: bottomJumpToKey,
          contentAlign: isDesktop ? ContentAlign.right : ContentAlign.top,
          iconData: Icons.search,
          contentTitle: lang.jumpToTabTutorialTitle,
          contentDescription: lang.jumpToTabTutorialDescription,
          isLast: true,
        ),
      ],
    );
  }
}
