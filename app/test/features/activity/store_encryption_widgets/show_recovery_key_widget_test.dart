import 'package:acter/features/activities/widgets/security_and_privacy_section/show_recovery_key_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_util.dart';

void main() {

  Future<void> pumpProviderWidget(
    WidgetTester tester, {
    required String recoveryKey,
    VoidCallback? onKeyDestroyed,
  }) async {
    await tester.pumpProviderWidget(
      child: ShowRecoveryKeyWidget(
        recoveryKey: recoveryKey,
        onKeyDestroyed: onKeyDestroyed,
      ),
    );
  }

  testWidgets('displays recovery key correctly', (WidgetTester tester) async {
    const testKey = 'test-recovery-key-123';
    await pumpProviderWidget(tester, recoveryKey: testKey);

    // Verify title is displayed
    expect(find.text('Your Backup Recover key'), findsOneWidget);
    
    // Verify recovery key is displayed
    expect(find.text(testKey), findsOneWidget);
    
    // Verify buttons are present
    expect(find.text('Don\'t remind me again'), findsOneWidget);
    expect(find.text('Okay'), findsOneWidget);
  });

  testWidgets('copies key to clipboard when copy button is pressed', (WidgetTester tester) async {
    const testKey = 'test-recovery-key-123';
    String? clipboardData;
    
    // Mock clipboard
    SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'Clipboard.setData') {
        clipboardData = methodCall.arguments['text'] as String;
      }
      return null;
    });

    await pumpProviderWidget(tester, recoveryKey: testKey);
    

    // Find and tap copy button
    await tester.tap(find.byIcon(Icons.copy_rounded));
    await tester.pump(); // Use pump() instead of pumpAndSettle() to avoid timer issues

    // Verify clipboard data
    expect(clipboardData, equals(testKey));
  });

  testWidgets('closes dialog when Okay is pressed', (WidgetTester tester) async {
    const testKey = 'test-recovery-key-123';
    bool dialogClosed = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Material(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ShowRecoveryKeyWidget(
                      recoveryKey: testKey,
                    ),
                  ).then((_) {
                    dialogClosed = true;
                  });
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pump();

    // Tap Okay button
    await tester.tap(find.text('Okay'));
    await tester.pump();

    // Verify dialog was closed
    expect(dialogClosed, isTrue);
  });
}