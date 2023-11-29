import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/super_invites.dart';
import '../support/spaces.dart';
import '../support/login.dart';
import '../support/setup.dart';

void subSpaceTests() {
  acterTestWidget('Invited user can see subspace', (t) async {
    final spaceId = await t.freshAccountWithSpace(userDisplayName: 'Alice');
    final subSpace = await t.createSpace('Subspace A', parentSpaceId: spaceId);
    final token = await t.createSuperInvite([spaceId]);

    // now let's try to create a new account with that token
    await t.logout();
    await t.freshAccount(registrationToken: token, displayName: 'Bob');

    // redeeming with the registration token should automatically trigger the invite process
    // check that we have been added.
    await t.gotoSpace(spaceId);

    // brings us to the related spaces view
    final spacesNav = find.byKey(const Key('spaces'));
    await t.tester.ensureVisible(spacesNav);
    await spacesNav.tap();

    // we can see the sub space
    final subSpaceSelector = find.byKey(Key('subspace-list-item-$subSpace'));
    await t.tester.ensureVisible(subSpaceSelector);
  });
}
