import 'package:acter/common/widgets/sliver_scaffold.dart';
import 'package:acter/features/link_room/pages/link_room_page.dart';
import 'package:acter/features/spaces/pages/sub_spaces_page.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/super_invites.dart';
import '../support/spaces.dart';
import '../support/login.dart';
import '../support/setup.dart';
import '../support/util.dart';

void subSpaceTests() {
  acterTestWidget(
    'Invited user can see subspace',
    (t) async {
      final spaceId = await t.freshAccountWithSpace(userDisplayName: 'Alice');
      final subSpace =
          await t.createSpace('Subspace A', parentSpaceId: spaceId);
      final token = await t.createSuperInvite([spaceId]);

      // now let's try to create a new account with that token
      await t.logout();
      await t.freshAccount(registrationToken: token, displayName: 'Bob');

      // redeeming with the registration token should automatically trigger the invite process
      // check that we have been added.
      await t.gotoSpace(spaceId, appTab: const Key('spaces'));

      // we can see the sub space
      final subSpaceSelector = find.byKey(Key('subspace-list-item-$subSpace'));
      await t.tester.ensureVisible(subSpaceSelector);
    },
    skip: true, // doesn't currently show up in the parent space. refs #1938
  );
  acterTestWidget(
    'Invited user can see subspace linked later',
    (t) async {
      final spaceId = await t.freshAccountWithSpace(userDisplayName: 'Alice');
      final subSpace = await t.createSpace('Subspace A');
      // not directly created this way, but linked later.
      await t.gotoSpace(spaceId);
      await t.navigateTo([
        const Key('spaces'),
        SubSpacesPage.moreOptionKey,
        SubSpacesPage.linkSpaceKey,
      ]);

      final roomListEntry = find.byKey(Key('room-list-link-$subSpace'));
      await t.tester.ensureVisible(roomListEntry);
      await roomListEntry.tap();

      // confirm join_rule update
      await find.byKey(LinkRoomPage.confirmJoinRuleUpdateKey).tap();

      // close the box
      final closeKey = find.byKey(SliverScaffold.closeKey);
      await t.tester.ensureVisible(closeKey);
      await closeKey.tap();

      final token = await t.createSuperInvite([spaceId]);

      // now let's try to create a new account with that token
      await t.logout();
      await t.freshAccount(registrationToken: token, displayName: 'Bob');

      // redeeming with the registration token should automatically trigger the invite process
      // check that we have been added.
      await t.gotoSpace(
        spaceId,
        appTab: const Key('spaces'),
      );

      // brings us to the related spaces view

      // we can see the sub space
      final subSpaceSelector = find.byKey(Key('subspace-list-item-$subSpace'));
      await t.tester.ensureVisible(subSpaceSelector);
    },
    skip: true, // doesn't currently show up in the parent space. refs #1938
  );

  acterTestWidget(
    "Invited user can't see subspace linked later without join_rule update",
    (t) async {
      final spaceId = await t.freshAccountWithSpace(userDisplayName: 'Alice');
      final subSpace = await t.createSpace('Subspace A');
      // not directly created this way, but linked later.
      await t.gotoSpace(spaceId);
      await t.navigateTo([
        const Key('spaces'),
        SubSpacesPage.moreOptionKey,
        SubSpacesPage.linkSpaceKey,
      ]);

      final roomListEntry = find.byKey(Key('room-list-link-$subSpace'));
      await t.tester.ensureVisible(roomListEntry);
      await roomListEntry.tap();

      // deny the join_rule update
      await find.byKey(LinkRoomPage.denyJoinRuleUpdateKey).tap();

      // close the box
      final closeKey = find.byKey(SliverScaffold.closeKey);
      await t.tester.ensureVisible(closeKey);
      await closeKey.tap();

      final token = await t.createSuperInvite([spaceId]);

      // now let's try to create a new account with that token
      await t.logout();
      await t.freshAccount(registrationToken: token, displayName: 'Bob');

      // redeeming with the registration token should automatically trigger the invite process
      // check that we have been added.
      await t.gotoSpace(spaceId);
      await t.navigateTo([
        const Key('spaces'),
      ]);

      // brings us to the related spaces view

      // and we can't see the sub space
      await find
          .byKey(Key('subspace-list-item-$subSpace'))
          .should(findsNothing);
    },
    skip: true, // doesn't currently show up in the parent space. refs #1938
  );
}
