import 'package:acter/common/toolkit/errors/error_dialog.dart';
import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_util.dart';

extension ErrorPageExtensions on WidgetTester {
  Future<void> ensureErrorPageWorks() async {
    await pumpProviderScopeOnce();
    expect(
      find.byKey(ErrorPage.dialogKey),
      findsOneWidget,
      reason: 'Error Dialog not present',
    );
  }

  Future<void> ensureErrorPageWithRetryWorks() async {
    await ensureErrorPageWorks();

    expect(
      find.byKey(ActerErrorDialog.retryBtn),
      findsOneWidget,
      reason: 'Confirm Button not present',
    );

    await tap(find.byKey(ActerErrorDialog.retryBtn));
    await pumpProviderScope(times: 2);
    // dialog is gone on retry working
    expect(
      find.byKey(ErrorPage.dialogKey),
      findsNothing,
      reason: 'Error Dialog did not disappear',
    );
  }
}
