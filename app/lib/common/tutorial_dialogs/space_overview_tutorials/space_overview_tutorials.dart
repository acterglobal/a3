import 'package:acter/common/tutorial_dialogs/show_tutorials.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

final spaceOverviewKey = GlobalKey();

const spaceOverviewPrefKey = 'spaceOverviewPrefKey';

void spaceOverviewTutorials({required BuildContext context}) async {
  final prefs = await sharedPrefs();
  final isShow = prefs.getBool(spaceOverviewPrefKey) ?? true;

  if (context.mounted && isShow) {
    showTutorials(
      context: context,
      onFinish: () async {
        await prefs.setBool(spaceOverviewPrefKey, false);
      },
      targets: [
        TargetFocus(
          identify: 'spaceOverviewKey',
          keyTarget: spaceOverviewKey,
          shape: ShapeLightFocus.RRect,
          paddingFocus: 10,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      L10n.of(context).spaceOverviewTutorialTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      L10n.of(context).spaceOverviewTutorialDescription,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
