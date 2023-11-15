import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/space/model/keys.dart';
import 'package:acter/features/space/widgets/space_header_profile.dart';
import 'package:acter/features/spaces/model/keys.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'login.dart';

typedef StepCallback = Future<void> Function(ConvenientTest);

extension ActerSpace on ConvenientTest {
  Future<String> createSpace(String title, {StepCallback? onCreateForm}) async {
    await find.byKey(Keys.mainNav).should(findsOneWidget);
    final homeKey = find.byKey(MainNavKeys.dashboardHome);
    await homeKey.should(findsOneWidget);
    await homeKey.tap();

    final spacesKey = find.byKey(DashboardKeys.widgetMySpacesHeader);
    await spacesKey.should(findsOneWidget);
    await spacesKey.tap();

    final actions = find.byKey(SpacesKeys.mainActions);
    await actions.should(findsOneWidget);
    await actions.tap();

    final createAction = find.byKey(SpacesKeys.actionCreate);
    await createAction.should(findsOneWidget);
    await createAction.tap();

    final titleField = find.byKey(CreateSpaceKeys.titleField);
    await titleField.should(findsOneWidget);
    await titleField.enterTextWithoutReplace(title);

    if (onCreateForm != null) {
      await onCreateForm(this);
    }

    final submit = find.byKey(CreateSpaceKeys.submitBtn);
    await tester.ensureVisible(submit);
    await submit.tap();

    // we should be forwarded to the space.

    final spaceHeader = find.byKey(SpaceKeys.header);
    await spaceHeader.should(findsOneWidget);
    // read the actual spaceId
    final header = spaceHeader.evaluate().first.widget as SpaceHeaderProfile;
    return header.spaceId;
  }

  Future<void> selectSpace(String spaceId) async {
    // open the drawer
    final selectSpacesKey = find.byKey(SelectSpaceFormField.openKey);
    await tester.ensureVisible(selectSpacesKey);
    await selectSpacesKey.tap();

    // select the space and close the drawer
    final select = find.byKey(Key('select-space-$spaceId'));
    await tester.ensureVisible(select);
    await select.tap();
  }

  Future<String> freshAccountWithSpace() async {
    await freshAccount();
    return await createSpace('My home Space');
  }
}
