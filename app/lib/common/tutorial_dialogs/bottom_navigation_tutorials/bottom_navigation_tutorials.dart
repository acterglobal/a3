import 'package:acter/common/tutorial_dialogs/show_tutorials.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

final dashboardKey = GlobalKey();
final updateKey = GlobalKey();
final chatsKey = GlobalKey();
final activityKey = GlobalKey();
final jumpToKey = GlobalKey();

const bottomNavigationPrefKey = 'bottomNavigationPrefKey';

void bottomNavigationTutorials({required BuildContext context}) async {
  final prefs = await sharedPrefs();
  final isShow = prefs.getBool(bottomNavigationPrefKey) ?? true;

  if (context.mounted && !isShow) {
    showTutorials(
      context: context,
      onFinish: () async {
        await prefs.setBool(bottomNavigationPrefKey, false);
      },
      targets: [
        TargetFocus(
          identify: 'updateKey',
          keyTarget: updateKey,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      'assets/images/empty_updates.svg',
                      semanticsLabel: 'state',
                      height: 150,
                      width: 150,
                    ),
                    const SizedBox(height: 50),
                    Text(
                      L10n.of(context).updatesTabTutorialTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      L10n.of(context).updatesTabTutorialDescription,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        TargetFocus(
          identify: 'dashboardKey',
          keyTarget: dashboardKey,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      'assets/images/empty_home.svg',
                      semanticsLabel: 'state',
                      height: 150,
                      width: 150,
                    ),
                    const SizedBox(height: 50),
                    Text(
                      L10n.of(context).homeTabTutorialTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      L10n.of(context).homeTabTutorialDescription,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        TargetFocus(
          identify: 'chatsKey',
          keyTarget: chatsKey,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      'assets/images/empty_chat.svg',
                      semanticsLabel: 'state',
                      height: 150,
                      width: 150,
                    ),
                    const SizedBox(height: 50),
                    Text(
                      L10n.of(context).chatsTabTutorialTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      L10n.of(context).chatsTabTutorialDescription,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        TargetFocus(
          identify: 'activityKey',
          keyTarget: activityKey,
          alignSkip: Alignment.bottomLeft,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      'assets/images/empty_activity.svg',
                      semanticsLabel: 'state',
                      height: 150,
                      width: 150,
                    ),
                    const SizedBox(height: 50),
                    Text(
                      L10n.of(context).activityTabTutorialTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      L10n.of(context).activityTabTutorialDescription,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        TargetFocus(
          identify: 'jumpToKey',
          keyTarget: jumpToKey,
          alignSkip: Alignment.bottomLeft,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.search,
                      size: 150,
                    ),
                    const SizedBox(height: 50),
                    Text(
                      L10n.of(context).jumpToTabTutorialTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      L10n.of(context).jumpToTabTutorialDescription,
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
