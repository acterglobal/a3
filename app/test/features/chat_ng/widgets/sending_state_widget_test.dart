import 'package:acter/common/toolkit/widgets/pulsating_icon.dart';
import 'package:acter/features/chat_ng/widgets/sending_state_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show EventSendState;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_util.dart';

class MockEventSendState extends Mock implements EventSendState {
  final String _state;
  final String? _error;

  MockEventSendState(this._state, [this._error]);

  @override
  String state() => _state;

  @override
  String? error() => _error;

  @override
  Future<bool> abort() async => true;
}

void main() {
  // Helper to pump a widget with localizations
  Future<void> pumpLocalizedWidget(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          L10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: L10n.supportedLocales,
        home: Material(child: child),
      ),
    );
  }

  group('SendingStateWidget Tests', () {
    testWidgets('displays pulsating icon for NotSentYet state', (tester) async {
      final mockState = MockEventSendState('NotSentYet');

      await tester.pumpWidget(
        MaterialApp(
          home: Material(child: SendingStateWidget(state: mockState)),
        ),
      );

      expect(find.byType(PulsatingIcon), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('displays check icon for Sent state', (tester) async {
      final mockState = MockEventSendState('Sent');

      await tester.pumpWidget(
        MaterialApp(
          home: Material(child: SendingStateWidget(state: mockState)),
        ),
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

      await pumpLocalizedWidget(tester, SendingStateWidget(state: mockState));

      expect(find.byIcon(Icons.error), findsOneWidget);
      // Don't test the exact text since it depends on localization
    });

    testWidgets('shows nothing for unknown state', (tester) async {
      final mockState = MockEventSendState('UnknownState');

      await tester.pumpWidget(
        MaterialApp(
          home: Material(child: SendingStateWidget(state: mockState)),
        ),
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

        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: SendingStateWidget(
                state: mockState,
                showSentIconOnUnknown: true,
              ),
            ),
          ),
        );

        expect(find.byType(SizedBox), findsNothing);
        expect(find.byIcon(Icons.check), findsOneWidget);
        expect(find.byIcon(Icons.error), findsNothing);
        expect(find.byType(PulsatingIcon), findsNothing);
      },
    );

    testWidgets(
      'explicitly setting showSentIconOnUnknown to false shows nothing for unknown states',
      (tester) async {
        final mockState = MockEventSendState('RandomState');

        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: SendingStateWidget(
                state: mockState,
                showSentIconOnUnknown: false,
              ),
            ),
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
        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: Row(children: [SendingStateWidget(state: sentState)]),
            ),
          ),
        );

        final sentIconColor =
            tester.widget<Icon>(find.byIcon(Icons.check)).color;

        // Now check an unknown state with the flag enabled
        final unknownState = MockEventSendState('Unknown');
        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: Row(
                children: [
                  SendingStateWidget(
                    state: unknownState,
                    showSentIconOnUnknown: true,
                  ),
                ],
              ),
            ),
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

      await pumpLocalizedWidget(tester, SendingStateWidget(state: mockState));

      await tester.tap(find.byIcon(Icons.error));
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.text('Test error message'), findsOneWidget);
    });
  });
}
