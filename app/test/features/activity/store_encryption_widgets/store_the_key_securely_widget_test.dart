import 'package:acter/features/activities/widgets/security_and_privacy_section/store_the_key_securely_widget.dart';
import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:acter/features/chat_ui_showcase/mocks/general/mock_option_string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show OptionString;
import 'package:acter/l10n/generated/l10n.dart';
import '../../../helpers/test_util.dart';

void main() {
  Future<void> pumpProviderWidget(
    WidgetTester tester, {
    required OptionString storedEncKey,
    required int timestamp,
  }) async {
    await tester.pumpProviderWidget(
      overrides: [
        storedEncKeyProvider.overrideWith(
          (ref) => Future.value(storedEncKey),
        ),
        storedEncKeyTimestampProvider.overrideWith(
          (ref) => Future.value(timestamp),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: const Scaffold(
          body: StoreTheKeySecurelyWidget(),
        ),
      ),
    );
    // Wait for async providers to complete
    await tester.pumpAndSettle();
  }

  testWidgets('displays widget when key is available', (WidgetTester tester) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await pumpProviderWidget(
      tester,
      storedEncKey: MockOptionString(mockText: 'test-recovery-key-123'),
      timestamp: now,
    );

    final context = tester.element(find.byType(StoreTheKeySecurelyWidget));
    final l10n = L10n.of(context);

    // Verify widget is displayed
    expect(find.text(l10n.storeTheKeySecurely), findsOneWidget);
    expect(find.text(l10n.showKey), findsOneWidget);
  });

  testWidgets('hides widget when key is empty', (WidgetTester tester) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await pumpProviderWidget(
      tester,
      storedEncKey: MockOptionString(mockText: ''),
      timestamp: now,
    );

    final context = tester.element(find.byType(StoreTheKeySecurelyWidget));
    final l10n = L10n.of(context);

    // Verify widget is not displayed
    expect(find.text(l10n.storeTheKeySecurely), findsNothing);
    expect(find.text(l10n.showKey), findsNothing);
  });

  testWidgets('hides widget when key is null', (WidgetTester tester) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await pumpProviderWidget(
      tester,
      storedEncKey: MockOptionString(mockText: null),
      timestamp: now,
    );

    final context = tester.element(find.byType(StoreTheKeySecurelyWidget));
    final l10n = L10n.of(context);

    // Verify widget is not displayed
    expect(find.text(l10n.storeTheKeySecurely), findsNothing);
    expect(find.text(l10n.showKey), findsNothing);
  });

  testWidgets('shows normal urgency color for recent key', (WidgetTester tester) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await pumpProviderWidget(
      tester,
      storedEncKey: MockOptionString(mockText: 'test-recovery-key-123'),
      timestamp: now,
    );

    // Verify normal urgency color is used
    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(button.style?.foregroundColor?.resolve({}), isNotNull);
  });

  testWidgets('shows warning urgency color for older key', (WidgetTester tester) async {
    final threeDaysAgo = DateTime.now()
        .subtract(const Duration(days: 4))
        .millisecondsSinceEpoch ~/ 1000;
    await pumpProviderWidget(
      tester,
      storedEncKey: MockOptionString(mockText: 'test-recovery-key-123'),
      timestamp: threeDaysAgo,
    );

    // Verify warning urgency color is used
    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(button.style?.foregroundColor?.resolve({}), isNotNull);
  });

  testWidgets('shows critical urgency color for very old key', (WidgetTester tester) async {
    final sevenDaysAgo = DateTime.now()
        .subtract(const Duration(days: 8))
        .millisecondsSinceEpoch ~/ 1000;
    await pumpProviderWidget(
      tester,
      storedEncKey: MockOptionString(mockText: 'test-recovery-key-123'),
      timestamp: sevenDaysAgo,
    );

    // Verify critical urgency color is used
    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(button.style?.foregroundColor?.resolve({}), isNotNull);
  });

  testWidgets('shows recovery key dialog when button is pressed', (WidgetTester tester) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await pumpProviderWidget(
      tester,
      storedEncKey: MockOptionString(mockText: 'test-recovery-key-123'),
      timestamp: now,
    );

    final context = tester.element(find.byType(StoreTheKeySecurelyWidget));
    final l10n = L10n.of(context);

    // Tap show key button
    await tester.tap(find.text(l10n.showKey));
    await tester.pumpAndSettle();

    // Verify dialog is shown
    expect(find.text(l10n.encryptionBackupRecovery), findsOneWidget);
    expect(find.text('test-recovery-key-123'), findsOneWidget);
  });
}