import 'package:acter/common/tutorial_dialogs/show_tutorials.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

final createNewSpaceKey = GlobalKey();
final joinExistingSpaceKey = GlobalKey();

const createOrJoinSpacePrefKey = 'createOrJoinSpacePrefKey';

Future<void> createOrJoinSpaceTutorials({required BuildContext context}) async {
  final prefs = await sharedPrefs();
  final isShow = prefs.getBool(createOrJoinSpacePrefKey) ?? true;

  if (context.mounted && isShow) {
    showTutorials(
      context: context,
      onFinish: () async {
        await prefs.setBool(createOrJoinSpacePrefKey, false);
      },
      targets: [
        TargetFocus(
          identify: 'createNewSpaceKey',
          keyTarget: createNewSpaceKey,
          shape: ShapeLightFocus.RRect,
          paddingFocus: 10,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      L10n.of(context).createSpaceTutorialTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      L10n.of(context).createSpaceTutorialDescription,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        TargetFocus(
          identify: 'joinExistingSpaceKey',
          keyTarget: joinExistingSpaceKey,
          shape: ShapeLightFocus.RRect,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      L10n.of(context).joinSpaceTutorialTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      L10n.of(context).joinSpaceTutorialDescription,
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
