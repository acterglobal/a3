import 'package:acter/common/toolkit/errors/error_dialog.dart';
import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/common/toolkit/errors/inline_error_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_util.dart';

extension ErrorPageExtensions on WidgetTester {
  Future<void> ensureErrorPageWorks({dumpOnError = true}) async {
    await pumpProviderScopeOnce();
    try {
      expect(
        find.byKey(ErrorPage.dialogKey),
        findsOneWidget,
        reason: 'Error Dialog not present',
      );
    } catch (e) {
      if (dumpOnError) {
        debugDumpApp();
      }
      rethrow;
    }
  }

  Future<void> ensureErrorPageWithRetryWorks({dumpOnError = true}) async {
    await ensureErrorPageWorks(dumpOnError: dumpOnError);

    expect(
      find.byKey(ActerErrorDialog.retryBtn),
      findsOneWidget,
      reason: 'Retry Button not present',
    );

    await tap(find.byKey(ActerErrorDialog.retryBtn));
    await pumpProviderScope(times: 5);
    try {
      // dialog is gone on retry working
      expect(
        find.byKey(ErrorPage.dialogKey),
        findsNothing,
        reason: 'Error Dialog did not disappear',
      );
    } catch (e) {
      if (dumpOnError) {
        debugDumpApp();
      }
      rethrow;
    }
  }

  Future<void> ensureInlineErrorWithRetryWorks({dumpOnError = true}) async {
    await pumpProviderScopeOnce();
    try {
      expect(
        find.byType(ActerInlineErrorButton),
        findsOneWidget,
        reason: 'Inline Error Button not found',
      );
      expect(
        find.byType(ActerErrorDialog),
        findsNothing,
        reason: 'Acter Dialog showed too early',
      );
      await tap(find.byType(ActerInlineErrorButton));
      await pumpProviderScopeOnce();
      expect(
        find.byType(ActerErrorDialog),
        findsOne,
        reason: "Acter Dialog didn't open",
      );

      expect(
        find.byKey(ActerErrorDialog.retryBtn),
        findsOneWidget,
        reason: 'Retry Button not present',
      );

      await tap(find.byKey(ActerErrorDialog.retryBtn));
      await pumpProviderScope(times: 10);
      // dialog is gone on retry working
      expect(
        find.byType(ActerErrorDialog),
        findsNothing,
        reason: 'Error Dialog did not disappear',
      );
    } catch (e) {
      if (dumpOnError) {
        debugDumpApp();
      }
      rethrow;
    }
  }
}
