import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/widgets/html_editor/html_editor.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/pins/pages/create_pin_page.dart';
import 'package:acter/features/pins/pages/pin_details_page.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/login.dart';
import '../support/setup.dart';
import '../support/spaces.dart';
import '../support/super_invites.dart';
import '../support/util.dart';

extension ActerNews on ConvenientTest {
  Future<void> goToPin(String pinId, {Key? appTab}) async {
    await find.byKey(Keys.mainNav).should(findsOneWidget);
    await navigateTo([
      MainNavKeys.dashboardHome,
      MainNavKeys.dashboardHome,
      MainNavKeys.quickJump,
      MainNavKeys.quickJump,
      QuickJumpKeys.pins,
    ]);

    final select = find.byKey(Key('pin-list-item-$pinId'));
    await tester.ensureVisible(select);
    await select.should(findsOneWidget);
    await select.longPress();

    if (appTab != null) {
      final selectedApp = find.byKey(appTab);
      await tester.ensureVisible(selectedApp);
      await selectedApp.should(findsOneWidget);
      await selectedApp.tap();
    }
  }

  Future<void> createPin(
    String spaceId,
    String title,
    String content,
    String url,
  ) async {
    await find.byKey(Keys.mainNav).should(findsOneWidget);
    final quickJumpKey = find.byKey(MainNavKeys.quickJump);
    await quickJumpKey.should(findsOneWidget);
    await quickJumpKey.tap();

    final pinActionKey = find.byKey(QuickJumpKeys.createPinAction);
    await tester.ensureVisible(pinActionKey);
    await pinActionKey.should(findsOneWidget);
    await pinActionKey.tap();

    final titleField = find.byKey(CreatePinPage.titleFieldKey);
    await titleField.should(findsOneWidget);
    await titleField.enterTextWithoutReplace(title);

    final descriptionField = find.byKey(CreatePinPage.descriptionFieldKey);
    await descriptionField.should(findsOneWidget);
    final textEditorState =
        (tester.firstState(descriptionField) as HtmlEditorState).editorState;
    await textEditorState.insertText(0, content, path: [0]);
    textEditorState.service.keyboardService!.closeKeyboard();
    await selectSpace(spaceId, SelectSpaceFormField.openKey);

    final submit = find.byKey(CreatePinPage.submitBtn);
    await tester.ensureVisible(submit);
    await submit.tap();
  }

  Future<String> editPin(String title, String content, String url) async {
    await find.byKey(PinDetailsPage.actionMenuKey).should(findsOneWidget);
    final actionMenuKey = find.byKey(PinDetailsPage.actionMenuKey);
    await actionMenuKey.tap();

    await find.byKey(PinDetailsPage.editBtnKey).should(findsOneWidget);
    final editBtnKey = find.byKey(PinDetailsPage.editBtnKey);
    await editBtnKey.tap();

    final titleField = find.byKey(PinDetailsPage.titleFieldKey);
    await titleField.should(findsOneWidget);
    await titleField.replaceText(title);

    final pinPage = find.byKey(PinDetailsPage.pinPageKey);
    await pinPage.should(findsOneWidget);
    final page = pinPage.evaluate().first.widget as PinDetailsPage;
    return page.pinId;
  }
}

void pinsTests() {
  acterTestWidget('Create Example Pin with URL can be seen by others',
      (t) async {
    final spaceId = await t.freshAccountWithSpace(
      userDisplayName: 'Alex',
      spaceDisplayName: 'Shared Pins Example',
    );
    await t.createPin(
      spaceId,
      'This is great',
      'This pin contains acter global link',
      'https://acter.global',
    );

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

  acterTestWidget(
      'Create Example Pin and Edit it with ensuring reflected changes are shown',
      (t) async {
    final spaceId = await t.freshAccountWithSpace(
      userDisplayName: 'Alex',
      spaceDisplayName: 'Pin Edit Example',
    );
    await t.createPin(
      spaceId,
      'Edit Pin Example',
      'This pin contains acter global link',
      'https://acter.global',
    );

    // we expect to be thrown to the pin screen and see our title

    final pinId = await t.editPin(
      'Acter Global website',
      ' and check out our website',
      'https://acter.global',
    );

    // lets re-route to this edited pin to see if changes reflected
    await t.goToPin(pinId);

    await find.text('Acter Global website').should(findsOneWidget);
    await find
        .text('This pin contains acter global link and check out our website')
        .should(findsOneWidget);
    await find.text('https://acter.global').should(findsOneWidget);
  });
}
