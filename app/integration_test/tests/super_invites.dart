import 'package:acter/features/super_invites/dialogs/redeem_dialog.dart';
import 'package:acter/features/super_invites/pages/create_super_invite_page.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/super_invites.dart';
import '../support/spaces.dart';
import '../support/login.dart';
import '../support/chats.dart';
import '../support/setup.dart';

void superInvitesTests() {
  acterTestWidget('Full user flow with registration', (t) async {
    final spaceId = await t.freshAccountWithSpace(userDisplayName: 'Alice');
    final token = await t.createSuperInvite([spaceId]);

    // now let's try to create a new account with that token
    await t.logout();
    await t.freshAccount(registrationToken: token, displayName: 'Bob');

    // redeeming with the registration token should automatically trigger the invite process
    // check that we have been added.
    await t.ensureIsMemberOfSpace(spaceId);
  });

  acterTestWidget('Full user flow redeeming after registration', (t) async {
    final spaceId = await t.freshAccountWithSpace(userDisplayName: 'Alice');
    final token = await t.createSuperInvite([spaceId]);

    // now let's try to create a new account with that token
    await t.logout();
    await t.freshAccount(displayName: 'Bob');
    await t.redeemSuperInvite(
      token,
      dialogTest: () async {
        final redeemInfo = find.byKey(redeemInfoKey);
        await redeemInfo.should(findsOneWidget);
        // info found
      },
    );

    // redeeming with the registration token should automatically trigger the invite process
    // check that we have been added.
    await t.ensureIsMemberOfSpace(spaceId);
    await t.ensureHasChats(counter: 0);
  });

  acterTestWidget('Full user flow with registration many spaces and chats',
      (t) async {
    final spaceId = await t.freshAccountWithSpace(userDisplayName: 'Alice');
    final chats = await t.createSpaceChats(spaceId, ['Random', 'General']);
    final spaceId2 = await t.createSpace('Second test space');
    final spaceId3 = await t.createSpace('Arils cave');
    final token = await t.createSuperInvite(
      [spaceId, spaceId2, spaceId3],
      chats: chats,
    );

    // now let's try to create a new account with that token
    await t.logout();
    await t.freshAccount(registrationToken: token, displayName: 'Bob');

    // redeeming with the registration token should automatically trigger the invite process
    // check that we have been added.
    await t.ensureIsMemberOfSpaces([spaceId, spaceId2, spaceId3]);
    await t.ensureHasChats(ids: chats);
  });

  acterTestWidget('Token with DM', (t) async {
    final spaceId = await t.freshAccountWithSpace(userDisplayName: 'Alice');
    final token = await t.createSuperInvite(
      [spaceId],
      onCreateForm: (t) async {
        // activate create-dm
        final spacesKey = find.byKey(CreateSuperInvitePage.createDmKey);
        await spacesKey.should(findsOneWidget);
        await spacesKey.tap();
      },
    );

    // now let's try to create a new account with that token
    await t.logout();
    await t.freshAccount(registrationToken: token, displayName: 'Bob');

    // redeeming with the registration token should automatically trigger the invite process
    // check that we have been added.
    await t.ensureIsMemberOfSpace(spaceId);
    await t.ensureHasChats(counter: 1);
  });

  acterTestWidget('Edit and redeem', (t) async {
    final spaceId = await t.freshAccountWithSpace(userDisplayName: 'Alice');
    final spaceId2 = await t.createSpace('Second test space');

    final token = await t.createSuperInvite([spaceId]);
    final tokenKey = find.byKey(Key('edit-token-$token'));
    await tokenKey.should(findsOneWidget);
    await tokenKey.tap();

    // remove the current space
    final removeSpace1 = find.byKey(Key('room-to-invite-$spaceId-remove'));
    await removeSpace1.should(findsOneWidget);
    await removeSpace1.tap();

    // add the new space

    final addSpaceBtn = find.byKey(CreateSuperInvitePage.addSpaceKey);
    await addSpaceBtn.should(findsOneWidget);
    await addSpaceBtn.tap();

    final select = find.byKey(Key('select-space-$spaceId2'));
    await t.tester.ensureVisible(select);
    await select.tap();

    // submit with the new list
    final submitBtn = find.byKey(CreateSuperInvitePage.submitBtn);
    await t.tester.ensureVisible(submitBtn);
    await submitBtn.should(findsOneWidget);
    await submitBtn.tap();

    // now let's try to create a new account with that token
    await t.logout();
    await t.freshAccount(registrationToken: token, displayName: 'Bob');

    // redeeming with the registration token should automatically trigger the invite process
    // check that we have been added.
    await t.ensureIsMemberOfSpace(spaceId2);
  });

  acterTestWidget("Deleted can't be reused", (t) async {
    await t.freshAccount(displayName: 'Alice');

    final token = await t.createSuperInvite([]);
    final tokenKey = find.byKey(Key('edit-token-$token'));
    await tokenKey.should(findsOneWidget);
    await tokenKey.tap();

    final deleteToken = find.byKey(CreateSuperInvitePage.deleteBtn);
    await deleteToken.should(findsOneWidget);
    await deleteToken.tap();

    // confirm...

    final deleteConfirm = find.byKey(CreateSuperInvitePage.deleteConfirm);
    await deleteConfirm.should(findsOneWidget);
    await deleteConfirm.tap();

    final editTokenKey = find.byKey(Key('edit-token-$token'));
    await editTokenKey.should(findsNothing);

    // let's try to create the same token again

    final tokenTxt = find.byKey(CreateSuperInvitePage.tokenFieldKey);
    await tokenTxt.should(findsOneWidget);
    await tokenTxt.enterTextWithoutReplace(token);

    final submitBtn = find.byKey(CreateSuperInvitePage.submitBtn);
    await t.tester.ensureVisible(submitBtn);
    await submitBtn.should(findsOneWidget);
    await submitBtn.tap();

    // we are staying on the create screen.
    final tokenTxtField = find.byKey(CreateSuperInvitePage.tokenFieldKey);
    await tokenTxtField.should(findsOneWidget);
    // not added
    await editTokenKey.should(findsNothing);
  });
}
