import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

void showTutorials({
  required BuildContext context,
  required List<TargetFocus> targets,
  Function()? onFinish,
  Function(TargetFocus)? onClickTarget,
  bool Function()? onSkip,
}) {
  TutorialCoachMark(
    targets: targets,
    onFinish: onFinish,
    onClickTarget: onClickTarget,
    onSkip: onSkip,
    alignSkip: Alignment.topRight,
  ).show(context: context);
}
