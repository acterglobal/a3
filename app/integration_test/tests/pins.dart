import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/pins/sheets/create_pin_sheet.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/login.dart';
import '../support/setup.dart';
import '../support/spaces.dart';
import '../support/super_invites.dart';
import '../support/util.dart';

extension ActerNews on ConvenientTest {
  Future<void> createPin(String spaceId, String text, String url) async {
    await find.byKey(Keys.mainNav).should(findsOneWidget);
    final quickJumpKey = find.byKey(MainNavKeys.quickJump);
    await quickJumpKey.should(findsOneWidget);
    await quickJumpKey.tap();

    final spacesKey = find.byKey(QuickJumpKeys.createPinAction);
    await spacesKey.should(findsOneWidget);
    await spacesKey.tap();

    final titleField = find.byKey(CreatePinSheet.titleFieldKey);
    await titleField.should(findsOneWidget);
    await titleField.enterTextWithoutReplace(text);

    final urlField = find.byKey(CreatePinSheet.urlFieldKey);
    await urlField.should(findsOneWidget);
    await urlField.enterTextWithoutReplace(url);

    await selectSpace(spaceId, SelectSpaceFormField.openKey);

    final submit = find.byKey(CreatePinSheet.submitBtn);
    await tester.ensureVisible(submit);
    await submit.tap();
  }
}

void pinsTests() {
  acterTestWidget('Create Example Pin with URL can be seen by others',
      (t) async {
    final spaceId = await t.freshAccountWithSpace(
      userDisplayName: 'Alex',
      spaceDisplayName: 'Shared Pins Example',
    );
    await t.createPin(spaceId, 'This is great', 'https://acter.global');

    // we expect to be thrown to the pin screen and see our title

    await find.text('This is great').should(findsAtLeast(1));

    final superInviteToken = await t.createSuperInvite([spaceId]);

    await t.logout();
    await t.freshAccount(
      registrationToken: superInviteToken,
      displayName: 'Beatrice',
    );

    await t.navigateTo([
      MainNavKeys.quickJump,
      QuickJumpKeys.pins,
    ]);

    await find.text('This is great').should(findsOneWidget);
  });
}
