import 'package:acter/common/toolkit/widgets/pulsating_icon.dart';
import 'package:acter/features/chat_ng/widgets/sending_error_dialog.dart';
import 'package:acter/features/chat_ng/widgets/sending_state_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show EventSendState;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickalert/widgets/quickalert_container.dart';
import 'package:mockingjay/mockingjay.dart';

import '../../../helpers/test_util.dart';

class MockEventSendState extends Mock implements EventSendState {
  final String _state;
  final String? _error;

  MockEventSendState(this._state, [this._error]) {
    when(() => state()).thenReturn(_state);
    when(() => error()).thenReturn(_error);
    when(() => abort()).thenAnswer((_) async => true);
  }
}

void main() {
  late MockNavigator navigator;

  setUp(() {
    navigator = MockNavigator();
    when(navigator.canPop).thenReturn(true);
    when(() => navigator.pop(any())).thenAnswer((_) async {});
  });

  group('SendingStateWidget Tests', () {
    testWidgets('displays pulsating icon for NotSentYet state', (tester) async {
      final mockState = MockEventSendState('NotSentYet');

      await tester.pumpProviderWidget(
        child: SendingStateWidget(state: mockState),
      );

      expect(find.byType(PulsatingIcon), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('displays check icon for Sent state', (tester) async {
      final mockState = MockEventSendState('Sent');

      await tester.pumpProviderWidget(
        child: SendingStateWidget(state: mockState),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byType(PulsatingIcon), findsNothing);
    });

    testWidgets('displays error button for SendingFailed state', (
      tester,
    ) async {
      final mockState = MockEventSendState(
        'SendingFailed',
        'Test error message',
      );

      await tester.pumpProviderWidget(
        child: SendingStateWidget(state: mockState),
      );

      expect(find.byIcon(Icons.error), findsOneWidget);
      // Don't test the exact text since it depends on localization
    });

    testWidgets('shows nothing for unknown state', (tester) async {
      final mockState = MockEventSendState('UnknownState');

      await tester.pumpProviderWidget(
        child: SendingStateWidget(state: mockState),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.byIcon(Icons.error), findsNothing);
      expect(find.byType(PulsatingIcon), findsNothing);
    });

    testWidgets(
      'shows sent icon for unknown state when showSentIconOnUnknown is true',
      (tester) async {
        final mockState = MockEventSendState('UnknownState');

        await tester.pumpProviderWidget(
          child: SendingStateWidget(
            state: mockState,
            showSentIconOnUnknown: true,
          ),
        );

        expect(find.byIcon(Icons.check), findsOneWidget);
        expect(find.byIcon(Icons.error), findsNothing);
        expect(find.byType(PulsatingIcon), findsNothing);
      },
    );

    testWidgets(
      'explicitly setting showSentIconOnUnknown to false shows nothing for unknown states',
      (tester) async {
        final mockState = MockEventSendState('RandomState');

        await tester.pumpProviderWidget(
          child: SendingStateWidget(
            state: mockState,
            showSentIconOnUnknown: false,
          ),
        );

        expect(find.byType(SizedBox), findsOneWidget);
        expect(find.byIcon(Icons.check), findsNothing);
      },
    );
    testWidgets(
      'shows the same check icon for both Sent and unknown states when enabled',
      (tester) async {
        // First check the Sent state
        final sentState = MockEventSendState('Sent');
        await tester.pumpProviderWidget(
          child: SendingStateWidget(
            state: sentState,
            showSentIconOnUnknown: true,
          ),
        );

        final sentIconColor =
            tester.widget<Icon>(find.byIcon(Icons.check)).color;

        // Now check an unknown state with the flag enabled
        final unknownState = MockEventSendState('Unknown');
        await tester.pumpProviderWidget(
          child: SendingStateWidget(
            state: unknownState,
            showSentIconOnUnknown: true,
          ),
        );

        final unknownIconColor =
            tester.widget<Icon>(find.byIcon(Icons.check)).color;

        // They should have the same color since they use the same method
        expect(unknownIconColor, equals(sentIconColor));
      },
    );

    testWidgets('error button shows dialog when tapped', (tester) async {
      final mockState = MockEventSendState(
        'SendingFailed',
        'Test error message',
      );

      await tester.pumpProviderWidget(
        child: SendingStateWidget(state: mockState),
      );

      await tester.tap(find.byIcon(Icons.error));
      await tester.pumpAndSettle();

      // Dialog should be visible with error message
      expect(find.text('Test error message'), findsOneWidget);
      // Don't test exact localized strings since they depend on the current locale
      expect(find.byType(AlertDialog), findsOneWidget);
      // Verify the dialog has both confirm and cancel buttons
      expect(
        find.text(
          L10n.of(tester.element(find.byType(SendingErrorDialog))).abortSending,
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          L10n.of(tester.element(find.byType(SendingErrorDialog))).close,
        ),
        findsOneWidget,
      );
    });
  });

  group('SendingErrorDialog Tests', () {
    testWidgets('shows error message and buttons', (tester) async {
      final mockState = MockEventSendState(
        'SendingFailed',
        'Test error message',
      );

      await tester.pumpProviderWidget(
        child: SendingErrorDialog(state: mockState),
      );

      // Verify error message is shown
      expect(find.text('Test error message'), findsOneWidget);

      // Verify dialog structure
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(QuickAlertContainer), findsOneWidget);

      final BuildContext context = tester.element(
        find.byType(SendingErrorDialog),
      );
      final lang = L10n.of(context);

      // Verify buttons
      expect(find.text(lang.close), findsOneWidget); // Cancel button
      expect(find.text(lang.abortSending), findsOneWidget); // abort button
    });

    testWidgets('calls abort when confirm button is tapped', (tester) async {
      final mockState = MockEventSendState(
        'SendingFailed',
        'Test error message',
      );

      await tester.pumpProviderWidget(
        navigatorOverride: navigator,
        child: Material(
          child: Builder(
            builder:
                (context) => ElevatedButton(
                  onPressed:
                      () => SendingErrorDialog.show(
                        context: context,
                        state: mockState,
                      ),

                  child: const Text('Show Dialog'),
                ),
          ),
        ),
      );

      // Show the dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // confirms the dialog is visible
      expect(find.byType(SendingErrorDialog), findsOneWidget);

      final BuildContext context = tester.element(
        find.byType(SendingErrorDialog),
      );
      final lang = L10n.of(context);

      // Find and tap the confirm (abort) button
      await tester.tap(find.text(lang.abortSending));
      await tester.pumpAndSettle();

      // Verify abort was called
      verify(() => mockState.abort()).called(1);

      // confirms the dialog is closed
      expect(find.byType(SendingErrorDialog), findsNothing);
    });

    testWidgets('closes dialog when cancel button is tapped', (tester) async {
      final mockState = MockEventSendState(
        'SendingFailed',
        'Test error message',
      );

      await tester.pumpProviderWidget(
        navigatorOverride: navigator,
        child: Material(
          child: Builder(
            builder:
                (context) => ElevatedButton(
                  onPressed:
                      () => SendingErrorDialog.show(
                        context: context,
                        state: mockState,
                      ),

                  child: const Text('Show Dialog'),
                ),
          ),
        ),
      );

      // Show the dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(
        find.byType(SendingErrorDialog),
      );
      final lang = L10n.of(context);

      // Find and tap the cancel button
      await tester.tap(find.text(lang.close));
      await tester.pumpAndSettle();

      // Verify dialog is no longer visible
      expect(find.byType(SendingErrorDialog), findsNothing);
    });

    testWidgets('shows default error message when error is null', (
      tester,
    ) async {
      final mockState = MockEventSendState('SendingFailed');

      await tester.pumpProviderWidget(
        child: SendingErrorDialog(state: mockState),
      );

      expect(find.text('Error sending message'), findsOneWidget);
    });
  });
}
