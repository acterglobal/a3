import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:acter/features/settings/super_invites/pages/create.dart';
import 'package:acter/features/settings/super_invites/pages/super_invites.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import '../support/login.dart';
import '../support/setup.dart';
import '../support/spaces.dart';

extension SuperInvites on ConvenientTest {
  Future<String> createSuperInvite(List<String> spaceIds) async {
    final newToken = 't${const Uuid().v4().toString()}'.substring(0, 8);
    await find.byKey(Keys.mainNav).should(findsOneWidget);
    final quickJumpKey = find.byKey(MainNavKeys.quickJump);
    await quickJumpKey.should(findsOneWidget);
    await quickJumpKey.tap();

    final spacesKey = find.byKey(QuickJumpKeys.settings);
    await spacesKey.should(findsOneWidget);
    await spacesKey.tap();

    final updateField = find.byKey(SettingsMenu.superInvitations);
    await updateField.should(findsOneWidget);
    await updateField.tap();

    final newTokenBtn = find.byKey(SuperInvitesPage.createNewToken);
    await newTokenBtn.should(findsOneWidget);
    await newTokenBtn.tap();

    final tokenTxt = find.byKey(CreateSuperInviteTokenPage.tokenFieldKey);
    await tokenTxt.should(findsOneWidget);
    await tokenTxt.enterTextWithoutReplace(newToken);

    for (final spaceId in spaceIds) {
      final addSpaceBtn = find.byKey(CreateSuperInviteTokenPage.addSpaceKey);
      await addSpaceBtn.should(findsOneWidget);
      await addSpaceBtn.tap();

      final select = find.byKey(Key('select-space-$spaceId'));
      await tester.ensureVisible(select);
      await select.tap();
    }

    final submitBtn = find.byKey(CreateSuperInviteTokenPage.submitBtn);
    await submitBtn.should(findsOneWidget);
    await submitBtn.tap();

    return newToken;
  }
}

void superInvitesTests() {
  tTestWidgets('Full User Flow', (t) async {
    disableOverflowErrors();
    final spaceId = await t.freshAccountWithSpace();
    final token = await t.createSuperInvite([spaceId]);

    // now let's try to create a new account with that token
    await t.logout();
    await t.freshAccount(registrationToken: token);

    // redeeming with the registration token should automatically trigger the invite process
    // check that we have been added.
    await t.ensureIsMemberOfSpace(spaceId);
  });
}
