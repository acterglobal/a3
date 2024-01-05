import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:acter/router/router.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'spaces.dart';

extension ActerUtil on ConvenientTest {
  Future<void> navigateTo(List<Key> keys) async {
    for (final key in keys) {
      final nextKey = find.byKey(key);
      await tester.ensureVisible(nextKey);
      await nextKey.should(findsOneWidget);
      await nextKey.tap();
    }
  }

  Future<void> ensureHasBackButton() async {
    await find.byWidgetPredicate((widget) => widget is BackButton).should(
          findsOneWidget,
          reason: 'Back button was expected but not found',
        );
  }

  Future<void> fillForm(
    Map<Key, String> fields, {
    Key? submitBtnKey,
    String? selectSpaceId,
  }) async {
    for (final entry in fields.entries) {
      final textField = find.byKey(entry.key);
      await tester.ensureVisible(textField);
      await textField.should(findsOneWidget);
      await textField.enterTextWithoutReplace(entry.value);
    }
    if (selectSpaceId != null) {
      await selectSpace(selectSpaceId);
    }
    if (submitBtnKey != null) {
      final submit = find.byKey(submitBtnKey);
      await tester.ensureVisible(submit);
      await submit.should(findsOneWidget);
      await submit.tap();
    }
  }

  Future<void> ensureLabEnabled(LabsFeature feat) async {
    if (!rootNavKey.currentContext!.read(isActiveProvider(feat))) {
      // ensure we do actually have access to the main nav.
      await find.byKey(Keys.mainNav).should(findsOneWidget);
      final quickJumpKey = find.byKey(MainNavKeys.quickJump);
      await quickJumpKey.should(findsOneWidget);
      await quickJumpKey.tap();

      final profileKey = find.byKey(QuickJumpKeys.settings);
      await profileKey.should(findsOneWidget);
      await profileKey.tap();

      final logoutKey = find.byKey(SettingsMenu.labs);
      await logoutKey.should(findsOneWidget);
      await logoutKey.tap();

      final confirmKey = find.byKey(Key('labs-${feat.name}'));
      await confirmKey.should(findsOneWidget);
      // let's read again
      if (!rootNavKey.currentContext!.read(isActiveProvider(feat))) {
        await confirmKey.tap();
      }

      await tester.pump(const Duration(seconds: 1));

      // ensure we are active
      assert(
        rootNavKey.currentContext!.read(isActiveProvider(feat)),
        'Could not activate $feat',
      );
    }
    // either way, go to home.
    await find.byKey(Keys.mainNav).should(findsOneWidget);
    final homeKey = find.byKey(MainNavKeys.dashboardHome);
    await homeKey.should(findsOneWidget);
    await homeKey.tap();
  }
}
