import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/onboarding/pages/redeem_invitations_page.dart';
import 'package:acter/common/providers/network_provider.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../helpers/mock_tasks_providers.dart';
import '../../../helpers/test_util.dart';
import '../../super_invites/mock_data/mock_super_invites.dart';

class MockSuperInviteInfo extends Mock implements SuperInviteInfo {}

void main() {
  late MockSuperInvites mockSuperInvites;

  setUp(() {
    mockSuperInvites = MockSuperInvites();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpRedeemInvitationsPage(WidgetTester tester) async {
    await tester.pumpProviderWidget(
      overrides: [
        superInvitesProvider.overrideWith(
          (ref) => Future.value(mockSuperInvites),
        ),
        hasNetworkProvider.overrideWith((_) => true),
      ],
      child: const RedeemInvitationsPage(username: 'testuser'),
    );
    await tester.pumpAndSettle();
  }

  group('RedeemInvitationsPage', () {
    testWidgets('renders correctly with initial state', (tester) async {
      await pumpRedeemInvitationsPage(tester);

      expect(find.text('Redeem Invitation'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
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

      // Tap get details button
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pump(); // Pump once for the tap
      await tester.pump(); // Pump again for the validation to complete

      // Get the form state after validation
      final formState = tester.state<FormState>(find.byType(Form));
      formState.validate();

      // Get the form field state after validation
      final formFieldState = tester.state<FormFieldState>(
        find.byType(TextFormField),
      ); // Check if the form field has an error
      expect(formFieldState.hasError, isTrue);
    });

    testWidgets('validates token input correctly', (tester) async {
      await pumpRedeemInvitationsPage(tester);

      // Test valid token
      await tester.enterText(find.byType(TextFormField), 'test_invite_code');
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle();
      expect(find.text('Please enter code'), findsNothing);

      // Verify the get details button is enabled with valid input
      final getDetailsButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton).first,
      );
      expect(getDetailsButton.onPressed, isNotNull);
    });

    testWidgets('shows get details button in correct state', (tester) async {
      await pumpRedeemInvitationsPage(tester);

      // Initially button should be disabled
      ElevatedButton getDetailsButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton).first,
      );
      expect(getDetailsButton.onPressed, isNull);

      // Enter valid token
      await tester.enterText(find.byType(TextFormField), 'test_invite_code');
      await tester.pump();

      // Button should be enabled
      getDetailsButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton).first,
      );
      expect(getDetailsButton.onPressed, isNotNull);
    });

    testWidgets('handles token changes correctly', (tester) async {
      await pumpRedeemInvitationsPage(tester);

      // Enter token
      await tester.enterText(find.byType(TextFormField), 'test_invite_code');
      await tester.pump();

      // Verify state changes
      expect(find.text('test_invite_code'), findsOneWidget);

      // Clear token
      await tester.enterText(find.byType(TextFormField), '');
      await tester.pump();

      // Verify empty state
      expect(find.text('test_invite_code'), findsNothing);
    });

    testWidgets('shows invite info when valid token is entered', (
      tester,
    ) async {
      // Set up mock SuperInviteInfo
      final mockSuperInviteInfo = MockSuperInviteInfo();
      when(
        () => mockSuperInviteInfo.inviterDisplayNameStr(),
      ).thenReturn('Test User');
      when(
        () => mockSuperInviteInfo.inviterUserIdStr(),
      ).thenReturn('@test:server.com');
      when(() => mockSuperInviteInfo.roomsCount()).thenReturn(2);

      // Set up mock SuperInvites getInfo method
      when(
        () => mockSuperInvites.info('test_invite_code'),
      ).thenAnswer((_) => Future.value(mockSuperInviteInfo));

      await pumpRedeemInvitationsPage(tester);

      // Enter valid token first
      await tester.enterText(find.byType(TextFormField), 'test_invite_code');
      await tester.pump();

      // Tap get details button
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle();

      expect(find.text('Test User'), findsOneWidget);
      expect(
        find.textContaining('Invited to you to join 2 room'),
        findsOneWidget,
      );
    });

    testWidgets('handles token redemption successfully', (tester) async {
      // Set up mock SuperInviteInfo
      final mockSuperInviteInfo = MockSuperInviteInfo();
      when(
        () => mockSuperInviteInfo.inviterDisplayNameStr(),
      ).thenReturn('Test User');
      when(
        () => mockSuperInviteInfo.inviterUserIdStr(),
      ).thenReturn('@test:server.com');
      when(() => mockSuperInviteInfo.roomsCount()).thenReturn(2);

      // Set up mock for info method
      when(
        () => mockSuperInvites.info('test_invite_code'),
      ).thenAnswer((_) => Future.value(mockSuperInviteInfo));

      // Set up mock for redeem method
      final mockRooms = MockFfiListFfiString();
      final mockToken = MockSuperInviteToken(mockFfiListFfiString: mockRooms);
      when(
        () => mockSuperInvites.redeem('test_invite_code'),
      ).thenAnswer((_) async => mockToken.rooms());

      await pumpRedeemInvitationsPage(tester);

      // Enter valid token
      await tester.enterText(find.byType(TextFormField), 'test_invite_code');
      await tester.pump();

      // Tap get details button
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle();

      // Tap redeem button
      await tester.tap(find.byType(ActerPrimaryActionButton));

      // Verify both info and redeem were called
      verify(() => mockSuperInvites.info('test_invite_code')).called(1);
      verify(() => mockSuperInvites.redeem('test_invite_code')).called(1);
    });

    testWidgets('handles token redemption failure', (tester) async {
      // Set up mock SuperInviteInfo for the info call
      final mockSuperInviteInfo = MockSuperInviteInfo();
      when(
        () => mockSuperInviteInfo.inviterDisplayNameStr(),
      ).thenReturn('Test User');
      when(
        () => mockSuperInviteInfo.inviterUserIdStr(),
      ).thenReturn('@test:server.com');
      when(() => mockSuperInviteInfo.roomsCount()).thenReturn(2);

      // Set up mock for info method
      when(
        () => mockSuperInvites.info('invalid_token'),
      ).thenAnswer((_) => Future.value(mockSuperInviteInfo));

      // Set up mock for redeem method to throw
      when(
        () => mockSuperInvites.redeem('invalid_token'),
      ).thenThrow(Exception('Invalid token'));

      await pumpRedeemInvitationsPage(tester);

      // Enter invalid token
      await tester.enterText(find.byType(TextFormField), 'invalid_token');
      await tester.pump();

      // Tap get details button to show invite info
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle();

      // Tap redeem button
      await tester.tap(find.byType(ActerPrimaryActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Added to 0 spaces & chats'), findsOneWidget);
    });

    testWidgets('loads saved token from SharedPreferences', (tester) async {
      SharedPreferences.setMockInitialValues({
        'invitation_token': 'test_invite_code',
      });

      await pumpRedeemInvitationsPage(tester);

      expect(
        find.widgetWithText(TextFormField, 'test_invite_code'),
        findsOneWidget,
      );
    });

    testWidgets('skip button is rendered correctly', (tester) async {
      await tester.pumpProviderWidget(
        child: const RedeemInvitationsPage(username: 'testuser'),
      );

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
  });
}
