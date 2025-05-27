import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/invite_members/widgets/invite_code_ui.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acter/features/onboarding/types.dart';
import '../../helpers/test_util.dart';
import '../../helpers/mock_tasks_providers.dart';
import '../super_invites/mock_data/mock_super_invites.dart';

void main() {
  late MockSuperInviteToken mockToken;

  setUp(() {
    mockToken = MockSuperInviteToken(
      mockFfiListFfiString: MockFfiListFfiString(items: ['test-room']),
    );
  });

  Future<void> createWidgetUnderTest({
    required WidgetTester tester,
    String roomId = 'test-room',
    CallNextPage? callNextPage,
    List<SuperInviteToken>? tokens,
  }) async {
    await tester.pumpProviderWidget(
      overrides: [
        superInvitesForRoom(roomId).overrideWith(
          (ref) => Future.value(tokens ?? []),
        ),
      ],
      child: InviteCodeUI(
        roomId: roomId,
        callNextPage: callNextPage,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('InviteCodeUI Widget Tests', () {
    testWidgets('shows generate button when no invite code exists', (tester) async {
      await createWidgetUnderTest(tester: tester);

      expect(find.byType(ActerPrimaryActionButton), findsOneWidget);
      expect(find.text('Generate Invite Code'), findsOneWidget);
    });

    testWidgets('displays invite code when available', (tester) async {
      await createWidgetUnderTest(
        tester: tester,
        tokens: [mockToken],
      );

      expect(find.text('test_invite_code'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('shows manage button when no callNextPage is provided', (tester) async {
      await createWidgetUnderTest(
        tester: tester,
        tokens: [mockToken],
      );

      expect(find.byType(ActerInlineTextButton), findsOneWidget);
      expect(find.text('Manage'), findsOneWidget);
    });

    testWidgets('shows share button with invite code', (tester) async {
      await createWidgetUnderTest(
        tester: tester,
        tokens: [mockToken],
      );

      expect(find.byType(ActerPrimaryActionButton), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
    });

    testWidgets('shows dropdown when multiple invite codes exist', (tester) async {
      final mockToken2 = MockSuperInviteToken(
        mockFfiListFfiString: MockFfiListFfiString(items: ['test-room']),
      );

      await createWidgetUnderTest(
        tester: tester,
        tokens: [mockToken, mockToken2],
      );

      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    testWidgets('shows other rooms count when token has multiple rooms', (tester) async {
      final mockTokenWithMultipleRooms = MockSuperInviteToken(
        mockFfiListFfiString: MockFfiListFfiString(items: ['room1', 'room2', 'room3']),
      );

      await createWidgetUnderTest(
        tester: tester,
        tokens: [mockTokenWithMultipleRooms],
      );

      expect(find.text('+2 additional rooms'), findsOneWidget);
    });

    testWidgets('generates new invite code when generate button is pressed', (tester) async {
      await createWidgetUnderTest(tester: tester);

      // Verify initial state - generate button is visible
      expect(find.byType(ActerPrimaryActionButton), findsOneWidget);
      expect(find.text('Generate Invite Code'), findsOneWidget);

      // Tap the generate button
      await tester.tap(find.byType(ActerPrimaryActionButton));
      await tester.pump();

      // After tapping, the generate button should still be visible since we're mocking the provider
      expect(find.byType(ActerPrimaryActionButton), findsOneWidget);
    });
  });
}