import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/onboarding/widgets/missing_encryption_backup_widget.dart';
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

  Future<void> pumpMissingEncryptionBackupWidget(WidgetTester tester) async {
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
              child: MissingEncryptionBackupPage(callNextPage: mockCallNextPage),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('MissingEncryptionBackupWidget', () {
    testWidgets('renders all UI elements correctly', (tester) async {
      await pumpMissingEncryptionBackupWidget(tester);

      // Verify headline text
      expect(find.byType(Text), findsNWidgets(6)); // Headline + 3 description texts + button texts

      // Verify warning icon
      expect(find.byIcon(PhosphorIcons.warning(PhosphorIconsStyle.regular)), findsOneWidget);

      // Verify action buttons
      expect(find.byType(ActerPrimaryActionButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('shows correct button texts', (tester) async {
      await pumpMissingEncryptionBackupWidget(tester);

      // Verify button texts
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Continue without Key'), findsOneWidget);
    });
  });
}

