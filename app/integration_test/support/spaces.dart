import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/chat/pages/room_page.dart';
import 'package:acter/features/chat/widgets/create_chat.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/space/pages/chats_page.dart';
import 'package:acter/features/space/providers/space_navbar_provider.dart';
import 'package:acter/features/space/widgets/space_header_profile.dart';
import 'package:acter/features/space/widgets/top_nav.dart';
import 'package:acter/features/spaces/model/keys.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'login.dart';
import 'util.dart';

typedef StepCallback = Future<void> Function(ConvenientTest);

extension ActerSpace on ConvenientTest {
  Future<void> ensureIsMemberOfSpace(String spaceId) async {
    await ensureIsMemberOfSpaces([spaceId]);
  }

  Future<void> ensureIsMemberOfSpaces(List<String> spaceIds) async {
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
      if (!selectedApp.tryEvaluate()) {
        // our tab might be hidden in the new submenu ..
        final moreKey = find.byKey(TopNavBar.moreTabsKey);
        await tester.ensureVisible(moreKey);
        await moreKey.should(findsOneWidget);
        await moreKey.tap();
      }
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
        TabEntry.chatsKey,
        SpaceChatsPage.actionsMenuKey,
        SpaceChatsPage.createChatKey,
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
  }) async {
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

    if (parentSpaceId != null) {
      await selectSpace(parentSpaceId, SelectSpaceFormField.openKey);
    }

    if (onCreateForm != null) {
      await onCreateForm(this);
    }

    final submit = find.byKey(CreateSpaceKeys.submitBtn);
    await tester.ensureVisible(submit);
    await submit.tap();

    // we should be forwarded to the space.

    final spaceHeader = find.byKey(SpaceHeaderProfile.headerKey);
    await spaceHeader.should(findsOneWidget);
    // read the actual spaceId
    final header = spaceHeader.evaluate().first.widget as SpaceHeaderProfile;
    return header.spaceId;
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
