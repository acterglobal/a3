// ignore_for_file: avoid_print

import 'package:acter/features/bug_report/pages/bug_report_page.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import '../support/login.dart';
import '../support/setup.dart';
import '../support/util.dart';

const rageshakeListUrl = String.fromEnvironment(
  'RAGESHAKE_LISTING_URL',
  defaultValue: '',
);

Future<String?> latestReportedLog() async {
  final url = Uri.parse(rageshakeListUrl);
  print('Connecting to $url');

  var response = await http.get(url);
  print('Response status: ${response.statusCode}');
  print('Response body: ${response.body}');
  if (response.statusCode == 404) {
    return null;
  }
  return response.body;
}

// extension ActerNews on ConvenientTest {
//   Future<void> createTextNews(String spaceId, String text) async {
//     await find.byKey(Keys.mainNav).should(findsOneWidget);
//     final quickJumpKey = find.byKey(MainNavKeys.quickJump);
//     await quickJumpKey.should(findsOneWidget);
//     await quickJumpKey.tap();

//     final spacesKey = find.byKey(QuickJumpKeys.createUpdateAction);
//     await spacesKey.should(findsOneWidget);
//     await spacesKey.tap();

//     final updateField = find.byKey(NewsUpdateKeys.textUpdateField);
//     await updateField.should(findsOneWidget);
//     await updateField.enterTextWithoutReplace(text);

//     await selectSpace(spaceId);

//     final submit = find.byKey(NewsUpdateKeys.submitBtn);
//     await tester.ensureVisible(submit);
//     await submit.tap();
//   }
// }

void bugReporterTests() {
  acterTestWidget('Can report bug', (t) async {
    if (rageshakeListUrl.isEmpty) {
      throw const Skip('Provide RAGESHAKE_LISTING_URL to run this test');
    }
    final prevReport = await latestReportedLog();
    // totally clean
    await t.freshAccount();
    await t.navigateTo([
      MainNavKeys.quickJump,
      QuickJumpKeys.bugReport,
    ]);

    await t.fillForm({
      BugReportPage.titleField: 'My first bug report',
    });
    final btn = find.byKey(BugReportPage.submitBtn);
    await btn.tap();
    // disappears until it was submitted.
    await btn.should(findsOne);

    final latestReport = await latestReportedLog();

    // successfully submitted
    assert(prevReport != latestReport);
    // we expect to be thrown to the news screen and see our latest item first:
  });
}
