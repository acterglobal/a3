import 'package:acter/features/onboarding/widgets/remindme_key_dialog.dart';
import 'package:acter/features/onboarding/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

void main() {
  setUpAll(() {
    // Initialize EasyLoading
    EasyLoading.instance
      ..displayDuration = const Duration(milliseconds: 2000)
      ..indicatorType = EasyLoadingIndicatorType.fadingCircle
      ..loadingStyle = EasyLoadingStyle.dark
      ..maskType = EasyLoadingMaskType.black
      ..dismissOnTap = false;
  });

  Future<void> pumpDialog(
    WidgetTester tester, {
    CallNextPage? callNextPage,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        builder: EasyLoading.init(),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => RemindMeAboutKeyDialog(
                    callNextPage: callNextPage,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ),
    );

    // Open the dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();
  }

  testWidgets('displays dialog with correct title and content', (WidgetTester tester) async {
    await pumpDialog(tester);

    final context = tester.element(find.byType(RemindMeAboutKeyDialog));
    final l10n = L10n.of(context);

    // Verify dialog title and content
    expect(find.text(l10n.remindMeLater), findsOneWidget);
    expect(find.text(l10n.remindMeAboutKeyLaterDescription), findsOneWidget);
  });

  testWidgets('displays correct button labels', (WidgetTester tester) async {
    await pumpDialog(tester);

    final context = tester.element(find.byType(RemindMeAboutKeyDialog));
    final l10n = L10n.of(context);

    // Verify button labels
    expect(find.text(l10n.remindMeAboutKeyLater), findsOneWidget);
    expect(find.text(l10n.cancel), findsOneWidget);
  });

  testWidgets('closes dialog when cancel button is pressed', (WidgetTester tester) async {
    await pumpDialog(tester);

    // Verify dialog is shown
    expect(find.byType(AlertDialog), findsOneWidget);

    // Tap cancel button
    await tester.tap(find.text(L10n.of(tester.element(find.byType(RemindMeAboutKeyDialog))).cancel));
    await tester.pumpAndSettle();

    // Verify dialog is closed
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('dialog has correct layout constraints', (WidgetTester tester) async {
    await pumpDialog(tester);

    // Find the content container
    final container = tester.widget<Container>(
      find.ancestor(
        of: find.text(L10n.of(tester.element(find.byType(RemindMeAboutKeyDialog))).remindMeAboutKeyLaterDescription),
        matching: find.byType(Container),
      ),
    );

    // Verify max width constraint
    expect(
      (container.constraints as BoxConstraints).maxWidth,
      equals(500),
    );
  });
}