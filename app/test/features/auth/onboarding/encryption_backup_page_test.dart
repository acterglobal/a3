import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:acter/features/onboarding/pages/encrption_backup_page.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../helpers/test_util.dart';

class MockBackupManager extends Mock implements BackupManager {}

void main() {
  late MockBackupManager mockBackupManager;

  setUp(() {
    mockBackupManager = MockBackupManager();
    // Set up default behavior for enable method
    when(
      () => mockBackupManager.enable(),
    ).thenAnswer((_) async => 'test-encryption-key');
  });

  group('EncryptionBackupPage', () {
    testWidgets('renders all basic components correctly', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          enableEncrptionBackUpProvider.overrideWith(
            (ref) => mockBackupManager.enable(),
          ),
        ],
        child: EncryptionBackupPage(callNextPage: () {}, username: 'test-username'),
      );

      // Verify basic structure
      final context = tester.element(find.byType(Text).last);

      //Test header icon
      expect(find.byIcon(PhosphorIcons.lockKey()), findsOneWidget);

      //Test header text
      expect(
        find.text(L10n.of(context).encryptionKeyBackupTitle),
        findsOneWidget,
      );

      //Test description text
      expect(
        find.text(L10n.of(context).encryptionKeyBackupDescription),
        findsOneWidget,
      );

      //Test encryption key container
      expect(find.byType(Container), findsOneWidget);

      //Test next button
      expect(find.byType(ElevatedButton), findsOneWidget);

      //Test remind me later button
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('displays loading indicator when fetching encryption key', (
      tester,
    ) async {
      await tester.pumpProviderWidget(
        overrides: [
          enableEncrptionBackUpProvider.overrideWith(
            (ref) => mockBackupManager.enable(),
          ),
        ],
        child: EncryptionBackupPage(callNextPage: () {}, username: 'test-username'),
      );

      //Encryption key loading indicator
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      //Encryption key text
      expect(find.text('test-encryption-key'), findsNothing);
    });

    testWidgets('displays encryption key when fetched', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          enableEncrptionBackUpProvider.overrideWith(
            (ref) => mockBackupManager.enable(),
          ),
        ],
        child: EncryptionBackupPage(callNextPage: () {}, username: 'test-username'),
      );

      // Initial pump to start the async operation
      await tester.pump();

      // Verify loading indicator is gone
      expect(find.byType(LinearProgressIndicator), findsNothing);

      
      expect(find.byKey(Key('encryption-key-input-field')), findsOneWidget);
      final textFormField = tester.widget<TextFormField>(
        find.byKey(Key('encryption-key-input-field')),
      );
      expect(textFormField.controller?.text, equals('test-encryption-key'));
    });

    testWidgets('shows error message when encryption key fetch fails', (
      tester,
    ) async {
      // Override the default behavior to throw an exception
      when(
        () => mockBackupManager.enable(),
      ).thenThrow(Exception('Failed to fetch key'));

      await tester.pumpProviderWidget(
        overrides: [
          enableEncrptionBackUpProvider.overrideWith(
            (ref) => mockBackupManager.enable(),
          ),
        ],
        child: EncryptionBackupPage(callNextPage: () {}, username: 'test-username'),
      );

      // Wait for the async operation to complete
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to fetch key'), findsOneWidget);
    });

    testWidgets('next button is disabled initially', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          enableEncrptionBackUpProvider.overrideWith(
            (ref) => mockBackupManager.enable(),
          ),
        ],
        child: EncryptionBackupPage(callNextPage: () {}, username: 'test-username'),
      );

      // Wait for the async operation to complete
      await tester.pumpAndSettle();

      final nextButton = find.byType(ElevatedButton);
      expect(nextButton, findsOneWidget);
      expect(tester.widget<ElevatedButton>(nextButton).onPressed, isNull);
    });
  });
}
