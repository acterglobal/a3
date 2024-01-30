// ignore_for_file: avoid_print

import 'package:acter/features/bug_report/pages/bug_report_page.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../support/login.dart';
import '../support/setup.dart';
import '../support/util.dart';

const rageshakeListUrl = String.fromEnvironment(
  'RAGESHAKE_LISTING_URL',
  defaultValue: '',
);

RegExp hrefRexp = RegExp(r'href="(.*?)"');

Future<List<String>> latestReported() async {
  final DateTime now = DateTime.now();
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  final String formatted = formatter.format(now);
  final fullBaseUrl = '$rageshakeListUrl/$formatted';
  final url = Uri.parse(fullBaseUrl);
  print('Reading from $url');

  var response = await http.get(url);
  print('Response status: ${response.statusCode}');
  if (response.statusCode == 404) {
    return [];
  }

  return hrefRexp.allMatches(response.body).map((e) {
    final inner = e[0];
    return '$rageshakeListUrl/$formatted/$inner';
  }).toList();
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
    final prevReports = await latestReported();
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

    final latestReports = await latestReported();

    // successfully submitted
    assert(prevReports.length < latestReports.length);
    // we expect to be thrown to the news screen and see our latest item first:

    // ensure the text field was reset
    final title = find.byKey(BugReportPage.titleField).evaluate().first.widget
        as TextFormField;
    assert(title.controller!.text == '', "title field wasn't reset");
  });
}
