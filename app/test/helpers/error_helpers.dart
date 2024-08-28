import 'package:acter/common/toolkit/errors/error_dialog.dart';
import 'package:acter/common/toolkit/errors/error_page.dart';
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
      reason: 'Confirm Button not present',
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
}
