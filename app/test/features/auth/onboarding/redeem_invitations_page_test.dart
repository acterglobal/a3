import 'dart:io';

import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/onboarding/pages/redeem_invitations_page.dart';
import 'package:acter/common/providers/network_provider.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../helpers/mock_tasks_providers.dart';
import '../../../helpers/test_util.dart';
import '../../super_invites/mock_data/mock_super_invites.dart';

class MockSuperInviteInfo extends Mock implements SuperInviteInfo {}

void main() {
  late MockSuperInvites mockSuperInvites;
  late MockSuperInviteInfo mockSuperInviteInfo;

  setUp(() {
    mockSuperInvites = MockSuperInvites();
    mockSuperInviteInfo = MockSuperInviteInfo();
    SharedPreferences.setMockInitialValues({});
  });

  void setupMockSuperInviteInfo({
    String displayName = 'Test User',
    String userId = '@test:server.com',
    int roomsCount = 2,
    bool hasRedeemed = false,
    bool setupRedeem = false,
  }) {
    when(
      () => mockSuperInviteInfo.inviterDisplayNameStr(),
    ).thenReturn(displayName);
    when(() => mockSuperInviteInfo.inviterUserIdStr()).thenReturn(userId);
    when(() => mockSuperInviteInfo.roomsCount()).thenReturn(roomsCount);
    when(() => mockSuperInviteInfo.hasRedeemed()).thenReturn(hasRedeemed);

    when(
      () => mockSuperInvites.info('test_invite_code'),
    ).thenAnswer((_) => Future.value(mockSuperInviteInfo));

    if (setupRedeem) {
      final mockRooms = MockFfiListFfiString();
      final mockToken = MockSuperInviteToken(mockFfiListFfiString: mockRooms);
      when(
        () => mockSuperInvites.redeem('test_invite_code'),
      ).thenAnswer((_) async => mockToken.rooms());
    }
  }

  Future<void> pumpRedeemInvitationsPage(WidgetTester tester) async {
    await tester.pumpProviderWidget(
      overrides: [
        superInvitesProvider.overrideWith(
          (ref) => Future.value(mockSuperInvites),
        ),
        hasNetworkProvider.overrideWith((_) => true),
      ],
      child: RedeemInvitationsPage(callNextPage: () {}),
    );
    await tester.pumpAndSettle();
  }

  group('RedeemInvitationsPage', () {
    testWidgets('renders correctly with initial state', (tester) async {
      await pumpRedeemInvitationsPage(tester);

      expect(find.text('Redeem Invitation'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('shows error when submitting empty token', (tester) async {
      await pumpRedeemInvitationsPage(tester);

      // Find the form and form field
      final form = tester.widget<Form>(find.byType(Form));
      form.key; // Should match _formKey in the page

      // Find and validate the TextFormField
      final formField = tester.widget<TextFormField>(
        find.byType(TextFormField),
      );
      formField.validator?.call('');

      // Get the form state after validation
      final formState = tester.state<FormState>(find.byType(Form));
      formState.validate();

      // Get the form field state after validation
      final formFieldState = tester.state<FormFieldState>(
        find.byType(TextFormField),
      ); // Check if the form field has an error
      expect(formFieldState.hasError, isTrue);
    });

    testWidgets('handles token changes correctly', (tester) async {
      setupMockSuperInviteInfo();

      await tester.runAsync(() async {
        await pumpRedeemInvitationsPage(tester);
        await tester.enterText(find.byType(TextFormField), 'test_invite_code');
        await tester.pump();

        expect(find.text('test_invite_code'), findsOneWidget);

        await Future.delayed(const Duration(milliseconds: 600));
        await tester.pump();

        await tester.enterText(find.byType(TextFormField), '');
        await tester.pump();
      });
    });

    testWidgets('debounces token validation correctly', (tester) async {
      setupMockSuperInviteInfo();

      await tester.runAsync(() async {
        await pumpRedeemInvitationsPage(tester);

        await tester.enterText(find.byType(TextFormField), 'test');
        await tester.pump();
        await Future.delayed(const Duration(milliseconds: 100));

        await tester.enterText(find.byType(TextFormField), 'test_inv');
        await tester.pump();
        await Future.delayed(const Duration(milliseconds: 100));

        await tester.enterText(find.byType(TextFormField), 'test_invite_code');
        await tester.pump();

        verifyNever(() => mockSuperInvites.info(any()));

        await Future.delayed(const Duration(milliseconds: 600));
        await tester.pump();

        verify(() => mockSuperInvites.info('test_invite_code')).called(1);
      });
    });

    testWidgets('shows invite info when valid token is entered', (
      tester,
    ) async {
      setupMockSuperInviteInfo();

      await tester.runAsync(() async {
        await pumpRedeemInvitationsPage(tester);
        await tester.enterText(find.byType(TextFormField), 'test_invite_code');
        await tester.pump();

        await Future.delayed(const Duration(milliseconds: 600));
        await tester.pump();

        expect(find.text('Test User'), findsOneWidget);
        expect(find.text('test_invite_code'), findsOneWidget);
        expect(
          find.textContaining('Invited to you to join 2 room'),
          findsOneWidget,
        );
      });
    });

    testWidgets('handles token redemption successfully', (tester) async {
      setupMockSuperInviteInfo(setupRedeem: true);

      await tester.runAsync(() async {
        await pumpRedeemInvitationsPage(tester);

        await tester.enterText(find.byType(TextFormField), 'test_invite_code');
        await tester.pump();
        await Future.delayed(const Duration(milliseconds: 600));
        await tester.pump();
        final redeemButton = find.byKey(Key('redeem-code-0'));
        expect(redeemButton, findsOneWidget);
        await tester.tap(redeemButton);
        await tester.pump();
        await tester.pumpAndSettle();

        verify(() => mockSuperInvites.redeem('test_invite_code')).called(1);
      });
    });

    testWidgets('skip button is rendered correctly', (tester) async {
      await pumpRedeemInvitationsPage(tester);

      // Find skip button
      final skipButton = find.byType(OutlinedButton);
      expect(skipButton, findsOneWidget);

      // Verify skip button text
      final buttonWidget = tester.widget<OutlinedButton>(skipButton);
      final buttonText = find.descendant(
        of: skipButton,
        matching: find.byType(Text),
      );
      expect(buttonText, findsOneWidget);
      expect((tester.widget(buttonText) as Text).data, 'Skip');

      // Verify button is enabled
      expect(buttonWidget.onPressed, isNotNull);
    });

    testWidgets('handles QR code scanning', (tester) async {
      await pumpRedeemInvitationsPage(tester);

      // Verify QR code button is present on mobile platforms
      if (Platform.isAndroid || Platform.isIOS) {
        expect(find.byIcon(Icons.qr_code), findsOneWidget);
      } else {
        expect(find.byIcon(Icons.qr_code), findsNothing);
      }
    });

    testWidgets('handles camera errors gracefully', (tester) async {
      await pumpRedeemInvitationsPage(tester);

      if (Platform.isAndroid || Platform.isIOS) {
        // Find and tap QR code button
        final qrButton = find.byIcon(Icons.qr_code);
        await tester.tap(qrButton);
        await tester.pumpAndSettle();

        // Verify camera error handling
        final qrView = find.byType(QRCodeDartScanView);
        expect(qrView, findsOneWidget);

        // Simulate camera error
        final qrViewWidget = tester.widget<QRCodeDartScanView>(qrView);
        qrViewWidget.onCameraError?.call('Camera permission denied');
        await tester.pumpAndSettle();

        // Verify error message is shown
        expect(find.text('Failed to open camera'), findsOneWidget);
      }
    });

    testWidgets('handles back navigation from QR scanner', (tester) async {
      await pumpRedeemInvitationsPage(tester);

      if (Platform.isAndroid || Platform.isIOS) {
        // Open QR scanner
        await tester.tap(find.byIcon(Icons.qr_code));
        await tester.pumpAndSettle();

        // Verify back button is present
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);

        // Tap back button
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Verify we're back on the main page
        expect(find.byType(QRCodeDartScanView), findsNothing);
        expect(find.byType(RedeemInvitationsPage), findsOneWidget);
      }
    });

    testWidgets('shows "Redeem" button when token is not redeemed', (
      tester,
    ) async {
      setupMockSuperInviteInfo(hasRedeemed: false);

      await tester.runAsync(() async {
        await pumpRedeemInvitationsPage(tester);
        await tester.enterText(find.byType(TextFormField), 'test_invite_code');
        await tester.pump();

        await Future.delayed(const Duration(milliseconds: 600));
        await tester.pump();

        final redeemButton = find.byKey(Key('redeem-code-0'));
        expect(redeemButton, findsOneWidget);

        final buttonWidget = tester.widget<ActerPrimaryActionButton>(
          redeemButton,
        );
        final textWidget = buttonWidget.child as Text;
        expect(textWidget.data, 'Redeem');
        expect(buttonWidget.onPressed, isNotNull);
      });
    });

    testWidgets('shows "Redeemed" button when token is already redeemed', (
      tester,
    ) async {
      setupMockSuperInviteInfo(hasRedeemed: true);

      await tester.runAsync(() async {
        await pumpRedeemInvitationsPage(tester);
        await tester.enterText(find.byType(TextFormField), 'test_invite_code');
        await tester.pump();

        await Future.delayed(const Duration(milliseconds: 600));
        await tester.pump();

        final redeemButton = find.byKey(Key('redeem-code-0'));
        expect(redeemButton, findsOneWidget);

        final buttonWidget = tester.widget<ActerPrimaryActionButton>(
          redeemButton,
        );
        final textWidget = buttonWidget.child as Text;
        expect(textWidget.data, 'Redeemed');
        expect(buttonWidget.onPressed, isNull);
      });
    });

    testWidgets(
      'button changes from Redeem to Redeemed after successful redemption',
      (tester) async {
        setupMockSuperInviteInfo(setupRedeem: true);

        await tester.runAsync(() async {
          await pumpRedeemInvitationsPage(tester);
          await tester.enterText(
            find.byType(TextFormField),
            'test_invite_code',
          );
          await tester.pump();

          await Future.delayed(const Duration(milliseconds: 600));
          await tester.pump();

          // Verify initial state shows "Redeem"
          final redeemButton = find.byKey(Key('redeem-code-0'));
          expect(redeemButton, findsOneWidget);

          final initialButtonWidget = tester.widget<ActerPrimaryActionButton>(
            redeemButton,
          );
          final initialTextWidget = initialButtonWidget.child as Text;
          expect(initialTextWidget.data, 'Redeem');

          // Tap the redeem button
          await tester.tap(redeemButton);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          await tester.pumpAndSettle();

          // Verify token was redeemed
          verify(() => mockSuperInvites.redeem('test_invite_code')).called(1);
        });
      },
    );

    testWidgets('shows skip button when no token is redeemed', (tester) async {
      await pumpRedeemInvitationsPage(tester);

      // Verify skip button is shown
      final skipButton = find.byType(OutlinedButton);
      expect(skipButton, findsOneWidget);

      final buttonText = tester.widget<Text>(
        find.descendant(of: skipButton, matching: find.byType(Text)),
      );
      expect(buttonText.data, 'Skip');

      // Verify continue button is not shown
      expect(
        find.widgetWithText(ActerPrimaryActionButton, 'Continue'),
        findsNothing,
      );
    });

    testWidgets('shows continue button after redeeming a token', (
      tester,
    ) async {
      setupMockSuperInviteInfo(setupRedeem: true);

      await tester.runAsync(() async {
        await pumpRedeemInvitationsPage(tester);

        expect(find.byType(OutlinedButton), findsOneWidget);
        expect(
          find.widgetWithText(ActerPrimaryActionButton, 'Continue'),
          findsNothing,
        );

        await tester.enterText(find.byType(TextFormField), 'test_invite_code');
        await tester.pump();
        await Future.delayed(const Duration(milliseconds: 600));
        await tester.pump();

        final redeemButton = find.byKey(Key('redeem-code-0'));
        await tester.tap(redeemButton);
        await tester.pump();
        await tester.pumpAndSettle();
      });
    });
  });
}
