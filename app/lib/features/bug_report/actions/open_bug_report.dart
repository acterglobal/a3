import 'package:acter/features/main/app_shell.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::bug_report::open_bug_report');

bool _bugReportOpen = false;

Future<void> openBugReport(
  BuildContext context, {
  Map<String, String>? queryParams,
}) async {
  if (_bugReportOpen) {
    return;
  }
  _bugReportOpen = true;
  try {
    queryParams = queryParams ?? {};
    final cacheDir = await appCacheDir();
    // rage shake disallows dot in filename
    final timestamp = DateTime.now().timestamp;
    final imagePath = await screenshotController.captureAndSave(
      cacheDir,
      fileName: 'screenshot_$timestamp.png',
    );
    if (imagePath != null) {
      queryParams['screenshot'] = imagePath;
    }
    if (!context.mounted) {
      _log.warning('Trying to open the bugreport without being mounted');
      return;
    }
    _bugReportOpen = true;
    await context.pushNamed(
      Routes.bugReport.name,
      queryParameters: queryParams,
    );
  } finally {
    _bugReportOpen = false;
  }
}
