import 'package:acter/features/onboarding/widgets/invite_friends_widget.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/member/widgets/user_search_results.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
        overrides: [
          superInvitesForRoom(testRoomId).overrideWith((ref) => Future.value([])),
        ],
      );
      await tester.pumpAndSettle();
      // Verify headline text is present
      expect(find.text('Invite Friends'), findsOneWidget);

      // Verify search bar is present
      expect(find.byType(ActerSearchWidget), findsOneWidget);
      expect(find.text('Search existing users'), findsOneWidget);

      // Verify invite externally section is present when no search
      expect(find.text('Invite externally'), findsOneWidget);
      expect(find.byIcon(PhosphorIcons.copy()), findsOneWidget);
      expect(find.byIcon(PhosphorIcons.qrCode()), findsOneWidget);

      // Verify action button
      expect(find.byType(ActerPrimaryActionButton), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('updates search value when text is entered', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        child: InviteFriendsWidget(roomId: testRoomId, callNextPage: () {}),
        overrides: [
          superInvitesForRoom(testRoomId).overrideWith((ref) => Future.value([])),
        ],
      );
      await tester.pumpAndSettle();

      // Find the search field and enter text
      final searchField = find.byType(ActerSearchWidget);
      await tester.enterText(searchField, 'test user');
      await tester.pumpAndSettle();

      // Verify the search value was updated
      final searchValue = tester.widget<ActerSearchWidget>(searchField);
      expect(searchValue.hintText, 'Search existing users');
    });

    testWidgets('shows search results when search value is entered', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        child: InviteFriendsWidget(roomId: testRoomId, callNextPage: () {}),
        overrides: [
          superInvitesForRoom(testRoomId).overrideWith((ref) => Future.value([])),
        ],
      );
      await tester.pumpAndSettle();

      // Enter search text
      final searchField = find.byType(ActerSearchWidget);
      await tester.enterText(searchField, 'test user');
      await tester.pumpAndSettle();


      // Verify search results section is shown
      expect(find.byType(UserSearchResults), findsOneWidget);
    });

    testWidgets('hides invite externally section when search text is entered', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        child: InviteFriendsWidget(roomId: testRoomId, callNextPage: () {}),
        overrides: [
          superInvitesForRoom(testRoomId).overrideWith((ref) => Future.value([])),
        ],
      );
      await tester.pumpAndSettle();

      // Verify invite externally section is initially visible
      expect(find.text('Invite externally'), findsOneWidget);
      expect(find.byIcon(PhosphorIcons.copy()), findsOneWidget);
      expect(find.byIcon(PhosphorIcons.qrCode()), findsOneWidget);

      // Enter search text
      final searchField = find.byType(ActerSearchWidget);
      await tester.enterText(searchField, 'test user');
      await tester.pumpAndSettle();

      // Verify invite externally section is hidden
      expect(find.text('Invite externally'), findsNothing);
      expect(find.byIcon(PhosphorIcons.copy()), findsNothing);
      expect(find.byIcon(PhosphorIcons.qrCode()), findsNothing);
    });

    testWidgets('shows invite externally section when search is cleared', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        child: InviteFriendsWidget(roomId: testRoomId, callNextPage: () {}),
        overrides: [
          superInvitesForRoom(testRoomId).overrideWith((ref) => Future.value([])),
        ],
      );
      await tester.pumpAndSettle();

      // Enter search text
      final searchField = find.byType(ActerSearchWidget);
      await tester.enterText(searchField, 'test user');
      await tester.pumpAndSettle();

      // Verify invite externally section is hidden
      expect(find.text('Invite externally'), findsNothing);

      // Clear search text
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();

      // Verify invite externally section is shown again
      expect(find.text('Invite externally'), findsOneWidget);
      expect(find.byIcon(PhosphorIcons.copy()), findsOneWidget);
      expect(find.byIcon(PhosphorIcons.qrCode()), findsOneWidget);
    });
  });
}

