import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acter/features/invite_members/pages/invite_individual_users.dart';
import 'package:acter/features/member/providers/invite_providers.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/invite_members/widgets/direct_invite.dart';

import '../../helpers/test_util.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InviteIndividualUsers Widget Tests', () {
    testWidgets('renders correctly with isFullPageMode true', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        child: const InviteIndividualUsers(roomId: 'test_room', isFullPageMode: true),
      );

      // Verify app bar is present
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Invite Individual Users'), findsOneWidget);

      // Verify search widget is present
      expect(find.byType(ActerSearchWidget), findsOneWidget);
    });

    testWidgets('renders correctly with isFullPageMode false', (WidgetTester tester) async {
      
      await tester.pumpProviderWidget(
        child: InviteIndividualUsers(
          roomId: 'test_room',
          isFullPageMode: false,
        ),
      );

      // Verify app bar is not present
      expect(find.byType(AppBar), findsNothing);

      // Verify next button is present
      expect(find.byType(ActerPrimaryActionButton), findsOneWidget);

      // Test next button functionality
      await tester.tap(find.byType(ActerPrimaryActionButton));
      await tester.pumpAndSettle();

    });

    testWidgets('search functionality updates provider', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          userSearchValueProvider.overrideWith((_) => null),
        ],
        child: const InviteIndividualUsers(roomId: 'test_room'),
      );

      // Find search field and enter text
      final searchField = find.byType(ActerSearchWidget);
      await tester.enterText(searchField, '@testuser:matrix.org');
      await tester.pump();

      // Verify the search value was updated by checking if DirectInvite is shown
      expect(find.byType(DirectInvite), findsNWidgets(2));
    });

    testWidgets('direct invite shows for valid usernames', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          userSearchValueProvider.overrideWith((_) => 'testuser:matrix.org'),
        ],
        child: const InviteIndividualUsers(roomId: 'test_room'),
      );

      // Verify DirectInvite widget is shown
      expect(find.byType(DirectInvite), findsOneWidget);
    });

    testWidgets('direct invite not shown for invalid usernames', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          userSearchValueProvider.overrideWith((_) => 'invalid@user'),
        ],
        child: const InviteIndividualUsers(roomId: 'test_room'),
      );

      // Verify DirectInvite widget is not shown
      expect(find.byType(DirectInvite), findsNothing);
    });
  });
}