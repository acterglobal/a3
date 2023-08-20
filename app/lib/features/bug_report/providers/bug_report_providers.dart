import 'package:acter/features/bug_report/models/bug_report.dart';
import 'package:acter/features/bug_report/providers/notifiers/bug_report_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bugReportProvider =
    StateNotifierProvider<BugReportStateNotifier, BugReport>(
  (ref) => BugReportStateNotifier(ref),
);
