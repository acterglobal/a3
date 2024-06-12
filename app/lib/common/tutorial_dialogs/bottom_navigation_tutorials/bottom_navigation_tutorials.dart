import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/tutorial_dialogs/show_tutorials.dart';
import 'package:acter/common/tutorial_dialogs/space_overview_tutorials/create_or_join_space_tutorials.dart';
import 'package:acter/common/tutorial_dialogs/target_focus.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

final dashboardKey = GlobalKey();
final updateKey = GlobalKey();
final chatsKey = GlobalKey();
final activityKey = GlobalKey();
final jumpToKey = GlobalKey();

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
          keyTarget: dashboardKey,
          contentAlign: isDesktop ? ContentAlign.right : ContentAlign.top,
          contentImageUrl: 'assets/images/empty_home.svg',
          contentTitle: L10n.of(context).homeTabTutorialTitle,
          contentDescription: L10n.of(context).homeTabTutorialDescription,
          isFirst: true,
        ),
        if (!isDesktop)
          targetFocus(
            identify: 'updateKey',
            keyTarget: updateKey,
            contentAlign: ContentAlign.top,
            contentImageUrl: 'assets/images/empty_updates.svg',
            contentTitle: L10n.of(context).updatesTabTutorialTitle,
            contentDescription: L10n.of(context).updatesTabTutorialDescription,
          ),
        targetFocus(
          identify: 'chatsKey',
          keyTarget: chatsKey,
          contentAlign: isDesktop ? ContentAlign.right : ContentAlign.top,
          contentImageUrl: 'assets/images/empty_chat.svg',
          contentTitle: L10n.of(context).chatsTabTutorialTitle,
          contentDescription: L10n.of(context).chatsTabTutorialDescription,
        ),
        targetFocus(
          identify: 'activityKey',
          keyTarget: activityKey,
          contentAlign: isDesktop ? ContentAlign.right : ContentAlign.top,
          contentImageUrl: 'assets/images/empty_activity.svg',
          contentTitle: L10n.of(context).activityTabTutorialTitle,
          contentDescription: L10n.of(context).activityTabTutorialDescription,
        ),
        targetFocus(
          identify: 'jumpToKey',
          keyTarget: jumpToKey,
          contentAlign: isDesktop ? ContentAlign.right : ContentAlign.top,
          iconData: Icons.search,
          contentTitle: L10n.of(context).jumpToTabTutorialTitle,
          contentDescription: L10n.of(context).jumpToTabTutorialDescription,
          isLast: true,
        ),
      ],
    );
  }
}
