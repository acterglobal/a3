import 'package:acter/features/bug_report/data/bug_report.dart';
import 'package:acter/features/bug_report/providers/notifiers/bug_report_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bugReportNotifierProvider =
    StateNotifierProvider<BugReportStateNotifier, BugReport>(
  (ref) => BugReportStateNotifier(ref),
);
