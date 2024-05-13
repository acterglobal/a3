import 'dart:async';

import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:acter/features/super_invites/dialogs/redeem_dialog.dart';
import 'package:acter/features/super_invites/pages/create.dart';
import 'package:acter/features/super_invites/pages/super_invites.dart';
import 'package:acter/features/super_invites/widgets/redeem_token.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import '../support/spaces.dart';
import '../support/util.dart';

extension SuperInvites on ConvenientTest {
  Future<String> createSuperInvite(
    List<String> spaceIds, {
    List<String>? chats,
    StepCallback? onCreateForm,
  }) async {
    final newToken = 't${const Uuid().v4().toString()}'.substring(0, 8);
    await find.byKey(Keys.mainNav).should(findsOneWidget);
    await navigateTo([
      MainNavKeys.quickJump,
      QuickJumpKeys.settings,
      SettingsMenu.superInvitations,
      SuperInvitesPage.createNewToken,
    ]);

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

    if (chats?.isNotEmpty == true) {
      for (final chatId in chats!) {
        final addSpaceBtn = find.byKey(CreateSuperInviteTokenPage.addChatKey);
        await addSpaceBtn.should(findsOneWidget);
        await addSpaceBtn.tap();

        final select = find.byKey(Key('select-chat-$chatId'));
        await tester.ensureVisible(select);
        await select.tap();
      }
    }

    if (onCreateForm != null) {
      await onCreateForm(this);
    }

    final submitBtn = find.byKey(CreateSuperInviteTokenPage.submitBtn);
    await tester.ensureVisible(submitBtn);
    await submitBtn.should(findsOneWidget);
    await submitBtn.tap();

    return newToken;
  }

  Future<void> redeemSuperInvite(
    String token, {
    FutureOr<void> Function()? dialogTest,
  }) async {
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

    final tokenTxt = find.byKey(RedeemToken.redeemTokenField);
    await tokenTxt.should(findsOneWidget);
    await tokenTxt.enterTextWithoutReplace(token);

    final submitBtn = find.byKey(RedeemToken.redeemTokenSubmit);
    await submitBtn.should(findsOneWidget);
    await submitBtn.tap();

    // opens the dialog we need to confirm now
    if (dialogTest != null) {
      await dialogTest();
    }

    final confirmBtn = find.byKey(redeemConfirmKey);
    await confirmBtn.should(findsOneWidget);
    await confirmBtn.tap();
  }
}
