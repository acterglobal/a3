import 'package:acter/common/tutorial_dialogs/bottom_navigation_tutorials/bottom_navigation_tutorials.dart';
import 'package:acter/common/tutorial_dialogs/space_overview_tutorials/create_or_join_space_tutorials.dart';
import 'package:acter/common/tutorial_dialogs/space_overview_tutorials/space_overview_tutorials.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

void showTutorials({
  required BuildContext context,
  required List<TargetFocus> targets,
  VoidCallback? onFinish,
}) {
  TutorialCoachMark(
    targets: targets,
    onFinish: onFinish,
    onClickTargetWithTapPosition: (targetFocus, tapDownDetails) {},
    onSkip: () {
      onSkip();
      return true;
    },
  ).show(context: context);
}

Future<void> onSkip() async {
  final prefs = await sharedPrefs();
  await prefs.setBool(bottomNavigationPrefKey, false);
  await prefs.setBool(createOrJoinSpacePrefKey, false);
  await prefs.setBool(spaceOverviewPrefKey, false);
}
