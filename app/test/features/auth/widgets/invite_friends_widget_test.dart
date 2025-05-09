import 'package:acter/features/onboarding/widgets/invite_friends_widget.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/member/widgets/user_search_results.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../helpers/test_util.dart';

class MockBuildContext extends Mock implements BuildContext {}

void main() {

  setUpAll(() {
    registerFallbackValue(MockBuildContext());
  });

  group('InviteFriendsWidget', () {
    const testRoomId = 'test_room_id';

    testWidgets('renders all UI elements correctly', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        child: InviteFriendsWidget(roomId: testRoomId, callNextPage: () {}),
      );

      // Verify headline text is present
      expect(find.text('Invite Friends'), findsOneWidget);

      // Verify search bar is present
      expect(find.byType(ActerSearchWidget), findsOneWidget);
      expect(find.text('Search existing users'), findsOneWidget);

      // Verify action buttons
      expect(find.byType(ActerPrimaryActionButton), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('updates search value when text is entered', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        child: InviteFriendsWidget(roomId: testRoomId, callNextPage: () {}),
      );

      // Find the search field and enter text
      final searchField = find.byType(ActerSearchWidget);
      await tester.enterText(searchField, 'test user');
      await tester.pump();

      // Verify the search value was updated
      final searchValue = tester.widget<ActerSearchWidget>(searchField);
      expect(searchValue.hintText, 'Search existing users');
    });

    testWidgets('shows search results when search value is entered', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        child: InviteFriendsWidget(roomId: testRoomId, callNextPage: () {}),
      );

      // Enter search text
      final searchField = find.byType(ActerSearchWidget);
      await tester.enterText(searchField, 'test user');
      await tester.pump();

      // Verify search results section is shown
      expect(find.byType(UserSearchResults), findsOneWidget);
    });

    testWidgets('shows search results list when text is entered', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        child: InviteFriendsWidget(roomId: testRoomId, callNextPage: () {}),
      );
      await tester.pumpAndSettle();

      // Verify list is not shown initially
      expect(find.byType(UserSearchResults), findsOneWidget);

      // Enter search text
      final searchField = find.byType(ActerSearchWidget);
      await tester.enterText(searchField, 'test user');
      await tester.pumpAndSettle();

      // Verify list is shown
      expect(find.byType(UserSearchResults), findsOneWidget);
    });

    testWidgets('updates search results list when search text changes', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        child: InviteFriendsWidget(roomId: testRoomId, callNextPage: () {}),
      );
      await tester.pumpAndSettle();

      // Enter initial search text
      final searchField = find.byType(ActerSearchWidget);
      await tester.enterText(searchField, 'test user');
      await tester.pumpAndSettle();

      // Verify initial list is shown
      expect(find.byType(UserSearchResults), findsOneWidget);

      // Change search text
      await tester.enterText(searchField, 'different user');
      await tester.pumpAndSettle();

      expect(find.byType(UserSearchResults), findsOneWidget);
    });

    testWidgets('shows invite externally section when no search text', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        child: InviteFriendsWidget(roomId: testRoomId, callNextPage: () {}),
      );
      await tester.pumpAndSettle();

      // Enter search text
      final searchField = find.byType(ActerSearchWidget);
      await tester.enterText(searchField, 'test user');
      await tester.pumpAndSettle();

      // Verify invite externally section is hidden
      expect(find.text('Invite externally'), findsNothing);
      expect(find.byIcon(Icons.copy), findsNothing);
      expect(find.byIcon(Icons.qr_code), findsNothing);
    });
  });
}

