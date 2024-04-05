import 'package:acter/common/tutorial_dialogs/show_tutorials.dart';
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

Future<void> onSkip() async {
  final prefs = await sharedPrefs();
  if (prefs.getBool(bottomNavigationPrefKey) ?? true) {
    await prefs.setBool(bottomNavigationPrefKey, false);
  }
}

void bottomNavigationTutorials({required BuildContext context}) async {
  final prefs = await sharedPrefs();
  final isShow = prefs.getBool(bottomNavigationPrefKey) ?? true;

  if (context.mounted && isShow) {
    showTutorials(
      context: context,
      onFinish: onSkip,
      onClickTarget: (targetFocus) => onSkip(),
      onSkip: () {
        onSkip();
        return true;
      },
      targets: [
        targetFocus(
          identify: 'updateKey',
          keyTarget: updateKey,
          contentAlign: ContentAlign.top,
          contentImageUrl: 'assets/images/empty_updates.svg',
          contentTitle: L10n.of(context).updatesTabTutorialTitle,
          contentDescription: L10n.of(context).updatesTabTutorialDescription,
        ),
        targetFocus(
          identify: 'dashboardKey',
          keyTarget: dashboardKey,
          contentAlign: ContentAlign.top,
          contentImageUrl: 'assets/images/empty_home.svg',
          contentTitle: L10n.of(context).homeTabTutorialTitle,
          contentDescription: L10n.of(context).homeTabTutorialDescription,
        ),
        targetFocus(
          identify: 'chatsKey',
          keyTarget: chatsKey,
          contentAlign: ContentAlign.top,
          contentImageUrl: 'assets/images/empty_chat.svg',
          contentTitle: L10n.of(context).chatsTabTutorialTitle,
          contentDescription: L10n.of(context).chatsTabTutorialDescription,
        ),
        targetFocus(
          identify: 'activityKey',
          keyTarget: activityKey,
          alignSkip: Alignment.bottomLeft,
          contentAlign: ContentAlign.top,
          contentImageUrl: 'assets/images/empty_activity.svg',
          contentTitle: L10n.of(context).activityTabTutorialTitle,
          contentDescription: L10n.of(context).activityTabTutorialDescription,
        ),
        targetFocus(
          identify: 'jumpToKey',
          keyTarget: jumpToKey,
          contentAlign: ContentAlign.top,
          alignSkip: Alignment.bottomLeft,
          iconData: Icons.search,
          contentTitle: L10n.of(context).jumpToTabTutorialTitle,
          contentDescription: L10n.of(context).jumpToTabTutorialDescription,
        ),
      ],
    );
  }
}
