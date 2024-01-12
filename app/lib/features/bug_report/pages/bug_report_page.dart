import 'dart:io';

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/bug_report/models/bug_report.dart';
import 'package:acter/features/bug_report/providers/bug_report_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BugReportPage extends ConsumerStatefulWidget {
  static const titleField = Key('bug-report-title');
  static const includeScreenshot = Key('bug-report-include-screenshot');
  static const includeLog = Key('bug-report-include-log');
  static const submitBtn = Key('bug-report-submit');
  final String? imagePath;

  const BugReportPage({super.key, this.imagePath});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BugReportState();
}

class _BugReportState extends ConsumerState<BugReportPage> {
  final formKey = GlobalKey<FormState>();

  Future<void> reportBug(BugReport report) async {
    final reportNotifier = ref.read(bugReportProvider.notifier);
    final loadingNotifier = ref.read(loadingProvider.notifier);
    try {
      String reportUrl = await reportNotifier.report(
        report.withScreenshot ? widget.imagePath : null,
      );
      String? issueId = getIssueId(reportUrl);
      loadingNotifier.update((state) => !state);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reported the bug successfully! (#$issueId)')),
        );
      }
    } catch (e) {
      loadingNotifier.update((state) => !state);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bug reporting failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bugReport = ref.watch(bugReportProvider);
    final reportNotifier = ref.watch(bugReportProvider.notifier);
    final isLoading = ref.watch(loadingProvider);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 350),
      child: Scaffold(
        appBar: AppBar(title: const Text('Report a problem')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text('Brief description of the issue'),
              const SizedBox(height: 10),
              TextFormField(
                key: BugReportPage.titleField,
                style: const TextStyle(color: Colors.white),
                onChanged: (value) => reportNotifier.setDescription(value),
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                key: BugReportPage.includeLog,
                title: const Text('Include current logs'),
                value: bugReport.withLog,
                onChanged: (bool? value) => reportNotifier.toggleLog(),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                key: BugReportPage.includeScreenshot,
                title: const Text('Include screenshot'),
                value: bugReport.withScreenshot,
                onChanged: (bool? value) => reportNotifier.toggleScreenshot(),
                controlAffinity: ListTileControlAffinity.leading,
                enabled: widget.imagePath != null,
              ),
              const SizedBox(height: 10),
              if (bugReport.withScreenshot)
                Image.file(
                  File(widget.imagePath!),
                  width: MediaQuery.of(context).size.width * 0.8,
                  errorBuilder: (
                    BuildContext ctx,
                    Object error,
                    StackTrace? stackTrace,
                  ) {
                    return Text('Could not load image due to $error');
                  },
                ),
              if (bugReport.withScreenshot) const SizedBox(height: 10),
              const Divider(endIndent: 10, indent: 10),
              const SizedBox(height: 10),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      key: BugReportPage.submitBtn,
                      onPressed: () async {
                        if (bugReport.description.isEmpty) {
                          _descriptionDialog();
                          return;
                        }
                        reportBug(bugReport);
                      },
                      child: const Text('Submit'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _descriptionDialog() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Empty description'),
        content: const Text('Please enter the issue description'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(),
            child: const Text('Ok'),
          ),
        ],
      ),
    );
  }
}
