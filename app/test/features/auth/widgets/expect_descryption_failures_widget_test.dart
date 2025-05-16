import 'package:acter/features/onboarding/widgets/expect_decryption_failures_widget.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../helpers/test_util.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  late VoidCallback mockCallNextPage;

  setUp(() {
    mockCallNextPage = () {};
  });

  Future<void> pumpExpectDecryptionFailures(WidgetTester tester) async {
    await tester.pumpProviderWidget(
      child: MaterialApp(
        localizationsDelegates: [
          L10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              height: 800, // Provide enough height to prevent overflow
              child: ExpectDecryptionFailures(callNextPage: mockCallNextPage),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ExpectDecryptionFailures', () {
    testWidgets('renders all UI elements correctly', (tester) async {
      await pumpExpectDecryptionFailures(tester);

      // Verify headline text
      expect(find.byType(Text), findsNWidgets(5)); // Headline + 2 description texts + button texts

      // Verify warning icon
      expect(find.byIcon(PhosphorIcons.warning(PhosphorIconsStyle.regular)), findsOneWidget);

      // Verify action buttons
      expect(find.byType(ActerPrimaryActionButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('shows correct button texts', (tester) async {
      await pumpExpectDecryptionFailures(tester);

      // Verify button texts
      expect(find.text('Go Back'), findsOneWidget);
      expect(find.text('Continue without Key'), findsOneWidget);
    });
  });
}

