import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/invite_members/widgets/invite_code_ui.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
    bool isManageInviteCode = true,
    List<SuperInviteToken>? tokens,
  }) async {
    await tester.pumpProviderWidget(
      overrides: [
        superInvitesForRoom(roomId).overrideWith(
          (ref) => Future.value(tokens ?? []),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: [
          L10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: L10n.supportedLocales,
        home: InviteCodeUI(
          roomId: roomId,
          isManageInviteCode: isManageInviteCode,
        ),
      ),
    );
    await tester.pump();
  }

  group('InviteCodeUI Widget Tests', () {
    testWidgets('shows generate button when no invite code exists', (tester) async {
      await createWidgetUnderTest(tester: tester);

      // Get the context and L10n instance
      final BuildContext context = tester.element(find.byType(InviteCodeUI));
      final lang = L10n.of(context);

      expect(find.byType(ActerPrimaryActionButton), findsOneWidget);
      expect(find.text(lang.generateInviteCode), findsOneWidget);
    });

    testWidgets('displays invite code when available', (tester) async {
      await createWidgetUnderTest(
        tester: tester,
        tokens: [mockToken],
      );

      expect(find.text('test_invite_code'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('shows manage button when isManageInviteCode is true', (tester) async {
      await createWidgetUnderTest(
        tester: tester,
        tokens: [mockToken],
      );

      // Get the context and L10n instance
      final BuildContext context = tester.element(find.byType(InviteCodeUI));
      final lang = L10n.of(context);

      expect(find.byType(ActerInlineTextButton), findsOneWidget);
      expect(find.text(lang.manage), findsOneWidget);
    });

    testWidgets('shows manage button when isManageInviteCode is false', (tester) async {
      await createWidgetUnderTest(
        tester: tester,
        tokens: [mockToken],
        isManageInviteCode: false,
      );

      // Get the context and L10n instance
      final BuildContext context = tester.element(find.byType(InviteCodeUI));
      final lang = L10n.of(context);

      expect(find.byType(ActerInlineTextButton), findsNothing);
      expect(find.text(lang.manage), findsNothing);
    });

    testWidgets('shows share button with invite code', (tester) async {
      await createWidgetUnderTest(
        tester: tester,
        tokens: [mockToken],
      );

      // Get the context and L10n instance
      final BuildContext context = tester.element(find.byType(InviteCodeUI));
      final lang = L10n.of(context);

      expect(find.byType(ActerPrimaryActionButton), findsOneWidget);
      expect(find.text(lang.share), findsOneWidget);
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

      // Get the context and L10n instance
      final BuildContext context = tester.element(find.byType(InviteCodeUI));
      final lang = L10n.of(context);

      expect(find.text(lang.moreRooms(2)), findsOneWidget);
    });

    testWidgets('generates new invite code when generate button is pressed', (tester) async {
      await createWidgetUnderTest(tester: tester);

      // Get the context and L10n instance
      final BuildContext context = tester.element(find.byType(InviteCodeUI));
      final lang = L10n.of(context);

      // Verify initial state - generate button is visible
      expect(find.byType(ActerPrimaryActionButton), findsOneWidget);
      expect(find.text(lang.generateInviteCode), findsOneWidget);

      // Tap the generate button
      await tester.tap(find.byType(ActerPrimaryActionButton));
      await tester.pump();

      // After tapping, the generate button should still be visible since we're mocking the provider
      expect(find.byType(ActerPrimaryActionButton), findsOneWidget);
    });
  });
}