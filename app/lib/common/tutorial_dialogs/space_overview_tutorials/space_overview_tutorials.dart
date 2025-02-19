import 'package:acter/common/tutorial_dialogs/show_tutorials.dart';
import 'package:acter/common/tutorial_dialogs/target_focus.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

const spaceOverviewPrefKey = 'spaceOverviewPrefKey';

Future<void> setSpaceOverviewTutorialsAsViewed() async {
  final prefs = await sharedPrefs();
  if (prefs.getBool(spaceOverviewPrefKey) ?? true) {
    await prefs.setBool(spaceOverviewPrefKey, false);
  }
}

void spaceOverviewTutorials({
  required BuildContext context,
  required GlobalKey spaceOverviewKey,
}) async {
  final prefs = await sharedPrefs();
  final isShow = prefs.getBool(spaceOverviewPrefKey) ?? true;

  if (context.mounted && isShow) {
    final lang = L10n.of(context);
    showTutorials(
      context: context,
      onFinish: setSpaceOverviewTutorialsAsViewed,
      onClickTarget: (targetFocus) => setSpaceOverviewTutorialsAsViewed(),
      onSkip: () {
        setSpaceOverviewTutorialsAsViewed();
        return true;
      },
      targets: [
        targetFocus(
          identify: 'spaceOverviewKey',
          keyTarget: spaceOverviewKey,
          contentAlign: ContentAlign.bottom,
          shape: ShapeLightFocus.RRect,
          paddingFocus: 10,
          contentTitle: lang.spaceOverviewTutorialTitle,
          contentDescription: lang.spaceOverviewTutorialDescription,
          isFirst: true,
          isLast: true,
        ),
      ],
    );
  }
}
