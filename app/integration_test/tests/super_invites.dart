import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:acter/features/settings/super_invites/pages/create.dart';
import 'package:acter/features/settings/super_invites/pages/super_invites.dart';
import 'package:acter/features/settings/super_invites/widgets/redeem_token.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import '../support/login.dart';
import '../support/setup.dart';
import '../support/spaces.dart';
import '../support/chats.dart';
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

    if (chats != null && chats.isNotEmpty) {
      for (final chatId in chats) {
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

  Future<void> redeemSuperInvite(String token) async {
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
  }
}

void superInvitesTests() {
  tTestWidgets('Full user flow with registration', (t) async {
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

  tTestWidgets('Full user flow redeeming after registration', (t) async {
    disableOverflowErrors();
    final spaceId = await t.freshAccountWithSpace();
    final token = await t.createSuperInvite([spaceId]);

    // now let's try to create a new account with that token
    await t.logout();
    await t.freshAccount();
    await t.redeemSuperInvite(token);

    // redeeming with the registration token should automatically trigger the invite process
    // check that we have been added.
    await t.ensureIsMemberOfSpace(spaceId);
    await t.ensureHasChats(counter: 0);
  });

  tTestWidgets('Full user flow with registration many spaces and chats',
      (t) async {
    disableOverflowErrors();
    final spaceId = await t.freshAccountWithSpace();
    final chats = await t.createSpaceChats(spaceId, ['Random', 'General']);
    final spaceId2 = await t.createSpace('Second test space');
    final spaceId3 = await t.createSpace('Arils cave');
    final token = await t.createSuperInvite(
      [spaceId, spaceId2, spaceId3],
      chats: chats,
    );

    // now let's try to create a new account with that token
    await t.logout();
    await t.freshAccount(registrationToken: token);

    // redeeming with the registration token should automatically trigger the invite process
    // check that we have been added.
    await t.ensureIsMemberOfSpaces([spaceId, spaceId2, spaceId3]);
    await t.ensureHasChats(ids: chats);
  });

  tTestWidgets('Token with DM', (t) async {
    disableOverflowErrors();
    final spaceId = await t.freshAccountWithSpace();
    final token = await t.createSuperInvite(
      [spaceId],
      onCreateForm: (t) async {
        // activate create-dm
        final spacesKey = find.byKey(CreateSuperInviteTokenPage.createDmKey);
        await spacesKey.should(findsOneWidget);
        await spacesKey.tap();
      },
    );

    // now let's try to create a new account with that token
    await t.logout();
    await t.freshAccount(registrationToken: token);

    // redeeming with the registration token should automatically trigger the invite process
    // check that we have been added.
    await t.ensureIsMemberOfSpace(spaceId);
    await t.ensureHasChats(counter: 1);
  });

  tTestWidgets('Edit and redeem', (t) async {
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
