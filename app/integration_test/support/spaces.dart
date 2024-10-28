import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/common/widgets/visibility/room_visibility_item.dart';
import 'package:acter/features/chat/pages/room_page.dart';
import 'package:acter/features/chat/widgets/create_chat.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/invite_members/pages/invite_page.dart';
import 'package:acter/features/room/model/room_visibility.dart';
import 'package:acter/features/space/widgets/space_sections/space_actions_section.dart';
import 'package:acter/features/spaces/model/keys.dart';
import 'package:acter/features/spaces/pages/create_space_page.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import 'login.dart';
import 'util.dart';

typedef StepCallback = Future<void> Function(ConvenientTest);

extension ActerSpace on ConvenientTest {
  Future<void> ensureIsMemberOfSpace(String spaceId) async {
    await ensureIsMemberOfSpaces([spaceId]);
  }

  Future<void> ensureIsMemberOfSpaces(List<String> spaceIds) async {
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    await find.byKey(Keys.mainNav).should(findsOneWidget);
    await navigateTo([
      MainNavKeys.dashboardHome,
      MainNavKeys.dashboardHome,
      DashboardKeys.widgetMySpacesHeader,
    ]);

    for (final spaceId in spaceIds) {
      final select = find.byKey(Key('space-list-item-$spaceId'));
      await tester.ensureVisible(select);
      await select.should(findsOneWidget);
    }
  }

  Future<void> gotoSpace(String spaceId, {Key? appTab}) async {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    await find.byKey(Keys.mainNav).should(findsOneWidget);
    await navigateTo([
      MainNavKeys.dashboardHome,
      MainNavKeys.dashboardHome,
      DashboardKeys.widgetMySpacesHeader,
    ]);

    final select = find.byKey(Key('space-list-item-$spaceId'));
    await tester.ensureVisible(select);
    await select.should(findsOneWidget);
    await select.tap();

    if (appTab != null) {
      final selectedApp = find.byKey(appTab);
      await tester.ensureVisible(selectedApp);
      await selectedApp.should(findsOneWidget);
      await selectedApp.tap();
    }
  }

  Future<List<String>> createSpaceChats(
    String spaceId,
    List<String> chatNames, {
    StepCallback? onCreateForm,
  }) async {
    List<String> chatIds = [];
    for (final chatname in chatNames) {
      await gotoSpace(spaceId);
      await navigateTo([
        SpaceActionsSection.createChatAction,
      ]);

      final titleField = find.byKey(CreateChatPage.chatTitleKey);
      await titleField.should(findsOneWidget);
      await titleField.enterTextWithoutReplace(chatname);

      if (onCreateForm != null) {
        await onCreateForm(this);
      }

      final submitBtn = find.byKey(CreateChatPage.submiteKey);
      await submitBtn.should(findsOneWidget);
      await submitBtn.tap();

      final roomPage = find.byKey(RoomPage.roomPageKey);
      await roomPage.should(findsOneWidget);
      // read the actual spaceId
      final page = roomPage.evaluate().first.widget as RoomPage;
      chatIds.add(page.roomId);
    }

    return chatIds;
  }

  Future<String> createSpace(
    String title, {
    StepCallback? onCreateForm,
    String? parentSpaceId,
    RoomVisibility? roomVisibility,
  }) async {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    await find.byKey(Keys.mainNav).should(findsOneWidget);
    await navigateTo([
      MainNavKeys.quickJump,
      MainNavKeys.quickJump,
      SpacesKeys.actionCreate,
    ]);

    final titleField = find.byKey(CreateSpaceKeys.titleField);
    await titleField.should(findsOneWidget);
    await titleField.enterTextWithoutReplace(title);

    if (parentSpaceId != null) {
      await selectSpace(parentSpaceId, SelectSpaceFormField.openKey);
    }

    if (onCreateForm != null) {
      await onCreateForm(this);
    }
    if (roomVisibility != null) {
      // open the drawer
      final selectSpacesKey = find.byKey(CreateSpacePage.permissionsKey);
      await tester.ensureVisible(selectSpacesKey);
      await selectSpacesKey.tap();
      final select = find.byKey(RoomVisibilityItem.generateKey(roomVisibility));
      await tester.ensureVisible(select);
      await select.tap();
    }

    final submit = find.byKey(CreateSpaceKeys.submitBtn);
    await tester.ensureVisible(submit);
    await submit.tap();

    // we should be forwarded to the space.

    final invitePage = find.byKey(InvitePage.invitePageKey);
    await invitePage.should(findsOneWidget);
    // read the actual spaceId
    final header = invitePage.evaluate().first.widget as InvitePage;
    return header.roomId;
  }

  Future<void> selectSpace(String spaceId, Key key) async {
    // open the drawer
    final selectSpacesKey = find.byKey(key);
    await tester.ensureVisible(selectSpacesKey);
    await selectSpacesKey.tap();

    // select the space and close the drawer
    final select = find.byKey(Key('select-space-$spaceId'));
    await tester.ensureVisible(select);

    await select.tap();
  }

  Future<String> freshAccountWithSpace({
    String? userDisplayName,
    String? spaceDisplayName,
  }) async {
    await freshAccount(displayName: userDisplayName);
    return await createSpace(spaceDisplayName ?? 'My home Space');
  }
}
