import 'package:acter/features/bug_report/actions/open_bug_report.dart';
import 'package:acter/features/bug_report/pages/bug_report_page.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/main/app_shell.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:acter/router/router.dart';
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

RegExp hrefRegExp = RegExp(r'href="(.*?)"');

Future<List<String>> latestReported() async {
  final DateTime now = DateTime.now();
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  final String formatted = formatter.format(now);
  final fullBaseUrl = '$rageshakeListUrl/$formatted';
  final url = Uri.parse(fullBaseUrl);
  debugPrint('Reading from $url');

  var response = await http.get(url);
  debugPrint('Response status: ${response.statusCode}');
  if (response.statusCode == 404) {
    return [];
  }

  return hrefRegExp.allMatches(response.body).map((e) {
    final inner = e[1];
    return '$inner';
  }).toList();
}

Future<List<String>> inspectReport(String reportName) async {
  debugPrint('fetching report $reportName');
  final DateTime now = DateTime.now();
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  final String formatted = formatter.format(now);
  final fullBaseUrl = '$rageshakeListUrl/$formatted/$reportName/';
  final url = Uri.parse(fullBaseUrl);
  debugPrint('Reading from $url');

  var response = await http.get(url);
  debugPrint('Response status: ${response.statusCode}');
  if (response.statusCode == 404) {
    throw 'report not found at $fullBaseUrl';
  }

  return hrefRegExp.allMatches(response.body).map((e) {
    final inner = e[1];
    return '$inner';
  }).toList();
}

Future<String> getReportDetails(String reportName) async {
  debugPrint('fetching report $reportName');
  final DateTime now = DateTime.now();
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  final String formatted = formatter.format(now);
  final fullBaseUrl = '$rageshakeListUrl/$formatted/$reportName/details.log.gz';
  final url = Uri.parse(fullBaseUrl);
  debugPrint('Reading from $url');

  var response = await http.get(url);
  debugPrint('Response status: ${response.statusCode}');
  if (response.statusCode == 404) {
    throw 'report not found at $fullBaseUrl';
  }

  return response.body;
}

void bugReporterTests() {
  acterTestWidget('Can report minimal bug', (t) async {
    if (rageshakeListUrl.isEmpty) {
      throw const Skip('Provide RAGESHAKE_LISTING_URL to run this test');
    }
    final prevReports = await latestReported();
    final page = find.byKey(BugReportPage.pageKey);
    // totally clean
    await t.freshAccount();
    await t.navigateTo([
      MainNavKeys.quickJump,
      QuickJumpKeys.bugReport,
    ]);

    await page.should(findsOne);
    await t.fillForm({
      BugReportPage.titleField: 'My first bug report',
    });
    final btn = find.byKey(BugReportPage.submitBtn);
    await btn.tap();
    // disappears when submission was successful
    await page.should(findsNothing);

    final latestReports = await latestReported();

    // successfully submitted
    assert(prevReports.length < latestReports.length);
    // let's inspect the report
    final reportedFiles = await inspectReport(latestReports.last);
    assert(
      reportedFiles.any((element) => element.startsWith('details')),
      'No app details founds in files: $reportedFiles',
    );
    assert(
      reportedFiles.length == 1,
      'Not only details were sent: $reportedFiles',
    );
    final reportDetails = await getReportDetails(latestReports.last);
    // ensure the details mean all is fine.
    assert(
      reportDetails.contains('Number of logs: 0'),
      'bad count of logs reported: $reportDetails',
    );
    assert(
      !reportDetails.contains('UserId:'),
      'UserID reported: $reportDetails',
    );

    // ensure the title was reset.
    await t.navigateTo([
      MainNavKeys.quickJump,
      QuickJumpKeys.bugReport,
    ]);

    await page.should(findsOne);
    final title = find.byKey(BugReportPage.titleField).evaluate().first.widget
        as TextFormField;
    assert(title.controller!.text == '', "title field wasn't reset");
  });

  acterTestWidget('Can report bug with logs & userId', (t) async {
    if (rageshakeListUrl.isEmpty) {
      throw const Skip('Provide RAGESHAKE_LISTING_URL to run this test');
    }
    final prevReports = await latestReported();
    final page = find.byKey(BugReportPage.pageKey);
    // totally clean
    final userId = await t.freshAccount();
    await t.navigateTo([
      MainNavKeys.quickJump,
      QuickJumpKeys.bugReport,
    ]);

    await page.should(findsOne);
    await t.fillForm({
      BugReportPage.titleField: 'A bug report with log and ID',
    });
    // turn on the log
    final withLog = find.byKey(BugReportPage.includeLog);
    await withLog.tap();

    // turn on the userId
    final withUserId = find.byKey(BugReportPage.includeUserId);
    await withUserId.tap();

    final btn = find.byKey(BugReportPage.submitBtn);
    await btn.tap();
    // disappears when submission was successful
    await page.should(findsNothing);

    final latestReports = await latestReported();

    // successfully submitted
    assert(prevReports.length < latestReports.length);
    // we expect to be thrown to the news screen and see our latest item first:

    await btn.should(findsNothing);

    final reportedFiles = await inspectReport(latestReports.last);
    assert(
      reportedFiles.any((element) => element.startsWith('details')),
      'No app details founds in files: $reportedFiles',
    );
    assert(
      reportedFiles.any((element) => element.startsWith('app_')),
      'No log found in files: $reportedFiles',
    );
    assert(
      reportedFiles.length == 2,
      'Not only details and log were sent: $reportedFiles',
    );
    // ensure the details mean all is fine.
    final reportDetails = await getReportDetails(latestReports.last);
    assert(
      reportDetails.contains('Number of logs: 1'),
      'bad count of logs reported: $reportDetails',
    );
    assert(
      reportDetails.contains('UserId: @$userId'),
      'UserID ($userId) not reported: $reportDetails',
    );

    // ensure the title was reset.
    await t.navigateTo([
      MainNavKeys.quickJump,
      QuickJumpKeys.bugReport,
    ]);

    await page.should(findsOne);
    final title = find.byKey(BugReportPage.titleField).evaluate().first.widget
        as TextFormField;
    assert(title.controller!.text == '', "title field wasn't reset");
  });

  acterTestWidget('Can report bug with screenshot from rageshake', (t) async {
    if (rageshakeListUrl.isEmpty) {
      throw const Skip('Provide RAGESHAKE_LISTING_URL to run this test');
    }
    final page = find.byKey(BugReportPage.pageKey);
    final prevReports = await latestReported();
    // totally clean
    await t.freshAccount();
    final AppShellState home = t.tester.state(find.byKey(appShellKey));
    // as if we shaked
    openBugReport(home.context);

    await page.should(findsOne);

    // let's shake again and make sure this all still closes properly
    openBugReport(home.context);
    openBugReport(home.context);

    final screenshot = find.byKey(BugReportPage.includeScreenshot);
    await screenshot.tap();

    // screenshot is shown
    await find.byKey(BugReportPage.screenshot).should(findsOneWidget);

    await t.fillForm({
      BugReportPage.titleField: 'bug report with screenshot',
    });

    final btn = find.byKey(BugReportPage.submitBtn);
    await btn.tap();
    // disappears when it was submitted.
    await page.should(findsNothing);

    final latestReports = await latestReported();

    // successfully submitted
    assert(prevReports.length < latestReports.length);
    // we expect to be thrown to the news screen and see our latest item first:

    final reportedFiles = await inspectReport(latestReports.last);
    assert(
      reportedFiles.any((element) => element.startsWith('screenshot')),
      'No screenshot founds in files: $reportedFiles',
    );
    assert(
      reportedFiles.length == 2,
      'Not only details and screenshot were sent: $reportedFiles',
    );
  });

  acterTestWidget('Can report bug with screenshot from quickjump', (t) async {
    if (rageshakeListUrl.isEmpty) {
      throw const Skip('Provide RAGESHAKE_LISTING_URL to run this test');
    }
    final page = find.byKey(BugReportPage.pageKey);
    final prevReports = await latestReported();
    // totally clean
    await t.freshAccount();
    await t.navigateTo([
      MainNavKeys.quickJump,
      QuickJumpKeys.bugReport,
    ]);

    await page.should(findsOne);

    final screenshot = find.byKey(BugReportPage.includeScreenshot);
    await screenshot.tap();

    // screenshot is shown
    await find.byKey(BugReportPage.screenshot).should(findsOneWidget);

    await t.fillForm({
      BugReportPage.titleField: 'bug report with screenshot',
    });

    final btn = find.byKey(BugReportPage.submitBtn);
    await btn.tap();
    // disappears when it was submitted.
    await page.should(findsNothing);

    final latestReports = await latestReported();

    // successfully submitted
    assert(prevReports.length < latestReports.length);
    // we expect to be thrown to the news screen and see our latest item first:

    final reportedFiles = await inspectReport(latestReports.last);
    assert(
      reportedFiles.any((element) => element.startsWith('screenshot')),
      'No screenshot founds in files: $reportedFiles',
    );
    assert(
      reportedFiles.length == 2,
      'Not only details and screenshot were sent: $reportedFiles',
    );
  });

  acterTestWidget('Can report bug with current & previous log', (t) async {
    if (rageshakeListUrl.isEmpty) {
      throw const Skip('Provide RAGESHAKE_LISTING_URL to run this test');
    }
    final prevReports = await latestReported();
    final page = find.byKey(BugReportPage.pageKey);
    // totally clean
    await t.freshAccount();
    await t.navigateTo([
      MainNavKeys.quickJump,
      QuickJumpKeys.bugReport,
    ]);

    await page.should(findsOne);
    await t.fillForm({
      BugReportPage.titleField: 'A bug report with previous & current log ',
    });
    // turn on the log
    final withLog = find.byKey(BugReportPage.includeLog);
    await withLog.tap();

    // turn on the userId
    final withPrevLog = find.byKey(BugReportPage.includePrevLog);
    await withPrevLog.tap();

    final btn = find.byKey(BugReportPage.submitBtn);
    await btn.tap();
    // disappears when submission was successful
    await page.should(findsNothing);

    final latestReports = await latestReported();

    // successfully submitted
    assert(prevReports.length < latestReports.length);
    // we expect to be thrown to the news screen and see our latest item first:

    await btn.should(findsNothing);

    final reportedFiles = await inspectReport(latestReports.last);
    assert(
      reportedFiles.any((element) => element.startsWith('details')),
      'No app details founds in files: $reportedFiles',
    );
    assert(
      reportedFiles.where((element) => element.startsWith('app_')).length == 2,
      'Expected 2 log files: $reportedFiles',
    );
    assert(
      reportedFiles.length == 3,
      'Not only details and log were sent: $reportedFiles',
    );
    // ensure the details mean all is fine.
    final reportDetails = await getReportDetails(latestReports.last);
    assert(
      reportDetails.contains('Number of logs: 2'),
      'bad count of logs reported: $reportDetails',
    );

    // ensure the title was reset.
    await t.navigateTo([
      MainNavKeys.quickJump,
      QuickJumpKeys.bugReport,
    ]);

    await page.should(findsOne);
    final title = find.byKey(BugReportPage.titleField).evaluate().first.widget
        as TextFormField;
    assert(title.controller!.text == '', "title field wasn't reset");
  });
}
