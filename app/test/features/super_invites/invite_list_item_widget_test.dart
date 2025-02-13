import 'package:acter/features/super_invites/widgets/invite_list_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../helpers/mock_tasks_providers.dart';
import '../../helpers/test_util.dart';

class MockSuperInviteToken extends Mock implements SuperInviteToken {
  @override
  String token() => 'FakeInviteCode';

  @override
  FfiListFfiString rooms() => MockFfiListFfiString();

  @override
  int acceptedCount() => 0;
}

void main() {
  group('InviteListItem Widget Tests', () {
    // Helper function to create the widget under test
    Future<void> createWidgetUnderTest({
      required WidgetTester tester,
      required MockSuperInviteToken inviteToken,
    }) async {
      await tester.pumpProviderWidget(
        child: InviteListItem(inviteToken: inviteToken),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('displays invite token and accepted count correctly',
        (tester) async {
      final inviteToken = MockSuperInviteToken();

      // Mock the methods of SuperInviteToken
      when(() => inviteToken.token()).thenReturn('invite_token_123');
      when(() => inviteToken.acceptedCount()).thenReturn(5);
      final mockFfiList = MockFfiListFfiString();
      mockFfiList.add(MockFfiString('room1')); // Add a room string to the list
      when(() => inviteToken.rooms()).thenReturn(mockFfiList);

      await createWidgetUnderTest(tester: tester, inviteToken: inviteToken);
      await tester.pumpAndSettle();
      expect(
        find.text('invite_token_123'),
        findsOneWidget,
      ); // Check if token is displayed
      expect(
        find.text('Used 5 times'),
        findsOneWidget,
      ); // Check if accepted count is displayed
      expect(find.byIcon(PhosphorIcons.share()), findsOneWidget);
    });

    testWidgets('display share button when room is available', (tester) async {
      final inviteToken = MockSuperInviteToken();

      // Mock the methods of SuperInviteToken
      when(() => inviteToken.token()).thenReturn('invite_token_123');
      when(() => inviteToken.acceptedCount()).thenReturn(5);
      final mockFfiList = MockFfiListFfiString();
      mockFfiList.add(MockFfiString('room1')); // Add a room string to the list
      when(() => inviteToken.rooms()).thenReturn(mockFfiList);

      await createWidgetUnderTest(tester: tester, inviteToken: inviteToken);
      await tester.pumpAndSettle();

      // Step 3: Verify that the share button (icon) is not displayed
      expect(find.byIcon(PhosphorIcons.share()), findsOne);
    });

    testWidgets('does not display share button when room is unavailable',
        (tester) async {
      final inviteToken = MockSuperInviteToken();

      // Mock the methods of SuperInviteToken
      when(() => inviteToken.token()).thenReturn('invite_token_123');
      when(() => inviteToken.acceptedCount()).thenReturn(5);
      final mockFfiList = MockFfiListFfiString();
      when(() => inviteToken.rooms()).thenReturn(mockFfiList);

      await createWidgetUnderTest(tester: tester, inviteToken: inviteToken);
      await tester.pumpAndSettle();

      // Step 3: Verify that the share button (icon) is not displayed
      expect(find.byIcon(PhosphorIcons.share()), findsNothing);
    });
  });
}
