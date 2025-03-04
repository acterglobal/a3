import 'package:acter/common/tutorial_dialogs/show_tutorials.dart';
import 'package:acter/common/tutorial_dialogs/target_focus.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

final createNewSpaceKey = GlobalKey(debugLabel: 'create new space');
final joinExistingSpaceKey = GlobalKey(debugLabel: 'join existing space');

const createOrJoinSpacePrefKey = 'createOrJoinSpacePrefKey';

Future<void> setCreateOrJoinSpaceTutorialAsViewed() async {
  final prefs = await sharedPrefs();
  if (prefs.getBool(createOrJoinSpacePrefKey) ?? true) {
    await prefs.setBool(createOrJoinSpacePrefKey, false);
  }
}

Future<void> createOrJoinSpaceTutorials({required BuildContext context}) async {
  final lang = L10n.of(context);
  final prefs = await sharedPrefs();
  final isShow = prefs.getBool(createOrJoinSpacePrefKey) ?? true;

  if (context.mounted && isShow) {
    showTutorials(
      context: context,
      onFinish: setCreateOrJoinSpaceTutorialAsViewed,
      onClickTarget: (targetFocus) => setCreateOrJoinSpaceTutorialAsViewed(),
      onSkip: () {
        setCreateOrJoinSpaceTutorialAsViewed();
        return true;
      },
      targets: [
        targetFocus(
          identify: 'createNewSpaceKey',
          keyTarget: createNewSpaceKey,
          contentAlign: ContentAlign.top,
          shape: ShapeLightFocus.RRect,
          contentTitle: lang.createSpaceTutorialTitle,
          contentDescription: lang.createSpaceTutorialDescription,
          isFirst: true,
        ),
        targetFocus(
          identify: 'joinExistingSpaceKey',
          keyTarget: joinExistingSpaceKey,
          contentAlign: ContentAlign.top,
          shape: ShapeLightFocus.RRect,
          contentTitle: lang.joinSpaceTutorialTitle,
          contentDescription: lang.joinSpaceTutorialDescription,
          isLast: true,
        ),
      ],
    );
  }
}
