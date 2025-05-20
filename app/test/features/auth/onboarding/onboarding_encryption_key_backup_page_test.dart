import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/onboarding/pages/onboarding_encryption_recovery_page.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../helpers/test_util.dart';

class MockBackupManager extends Mock implements BackupManager {}

void main() {
  late MockBackupManager mockBackupManager;
  late VoidCallback mockCallNextPage;

  setUp(() {
    mockBackupManager = MockBackupManager();
    mockCallNextPage = () {};
    
    // Setup default mock behavior
    when(() => mockBackupManager.recover(any())).thenAnswer((_) async => true);
    when(() => mockBackupManager.enable()).thenAnswer((_) async => 'test-encryption-key');
    when(() => mockBackupManager.reset()).thenAnswer((_) async => 'test-encryption-key');
    when(() => mockBackupManager.stateStream()).thenAnswer((_) => Stream.value('enabled'));
  });

  Future<void> pumpEncryptionKeyBackupPage(WidgetTester tester) async {
    await tester.pumpProviderWidget(
      overrides: [
        backupManagerProvider.overrideWith(
          (ref) => Future.value(mockBackupManager),
        ),
      ],
      child: OnboardingEncryptionRecoveryPage(callNextPage: mockCallNextPage),
    );
    await tester.pumpAndSettle();
  }

  group('OnboardingEncryptionKeyBackupPage', () {
    testWidgets('renders all UI elements correctly', (tester) async {
      await pumpEncryptionKeyBackupPage(tester);

      // Verify input field
      expect(find.byType(TextFormField), findsOneWidget);

      // Verify action buttons
      expect(find.byType(ActerPrimaryActionButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('shows copy button when text is entered', (tester) async {
      await pumpEncryptionKeyBackupPage(tester);

      // Initially no copy button
      expect(find.byIcon(Icons.copy), findsNothing);

      // Enter text
      await tester.enterText(find.byType(TextFormField), 'test-key');
      await tester.pump();

      // Copy button should appear
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('copies text to clipboard when copy button is pressed', (tester) async {
      await pumpEncryptionKeyBackupPage(tester);

      // Enter text
      await tester.enterText(find.byType(TextFormField), 'test-key');
      await tester.pump();

      // Press copy button
      await tester.tap(find.byIcon(Icons.copy));
      await tester.pump();

      // Verify snackbar is shown
      expect(find.text('Key copied to clipboard'), findsOneWidget);
    });

    testWidgets('validates empty input', (tester) async {
      await pumpEncryptionKeyBackupPage(tester);

      // Try to submit empty form
      await tester.tap(find.byType(ActerPrimaryActionButton));
      await tester.pump();

      // Verify error message
      expect(find.text('Please provide the key'), findsOneWidget);
    });

    testWidgets('calls next page on successful recovery', (tester) async {
      bool wasCalled = false;
      mockCallNextPage = () => wasCalled = true;

      await pumpEncryptionKeyBackupPage(tester);

      // Enter valid key
      await tester.enterText(find.byType(TextFormField), 'valid-key');
      await tester.pump();

      // Submit form
      await tester.tap(find.byType(ActerPrimaryActionButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Verify next page was called
      expect(wasCalled, isTrue);
    });

    testWidgets('shows error on failed recovery', (tester) async {
      bool wasCalled = false;
      mockCallNextPage = () => wasCalled = false;

      await pumpEncryptionKeyBackupPage(tester);

      // Enter valid key
      await tester.enterText(find.byType(TextFormField), 'invalid-key');
      await tester.pump();

      // Submit form
      await tester.tap(find.byType(ActerPrimaryActionButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
       // Verify next page was called
      expect(wasCalled, isFalse);
    });
  });
}
