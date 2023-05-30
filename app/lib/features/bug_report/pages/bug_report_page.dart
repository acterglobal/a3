import 'dart:io';

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/custom_button.dart';
import 'package:acter/features/bug_report/data/bug_report.dart';
import 'package:acter/features/bug_report/providers/bug_report_providers.dart';
import 'package:acter/features/bug_report/widgets/select_tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BugReportPage extends ConsumerStatefulWidget {
  final String? imagePath;

  const BugReportPage({Key? key, this.imagePath}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BugReportState();
}

class _BugReportState extends ConsumerState<BugReportPage> {
  final formKey = GlobalKey<FormState>();

  Future<void> reportBug(BugReport report) async {
    String? reportUrl = await ref
        .read(
          bugReportNotifierProvider.notifier,
        )
        .report(
          report.withScreenshot ? widget.imagePath : null,
        );
    String msg = 'Error occurred in bug report';
    if (reportUrl != null) {
      String? issueId = getIssueId(reportUrl);
      msg = 'Reported the bug successfully! (#$issueId)';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bugReport = ref.watch(bugReportNotifierProvider);
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
              const Text('Issue description'),
              const SizedBox(height: 10),
              TextFormField(
                style: const TextStyle(color: Colors.white),
                onChanged: (value) => ref
                    .read(bugReportNotifierProvider.notifier)
                    .setDescription(value),
              ),
              const SizedBox(height: 10),
              const Text(
                'Issue tag(s)',
              ),
              const SizedBox(height: 10),
              SelectTag(),
              const SizedBox(height: 10),
              CheckboxListTile(
                title: const Text('Including log file'),
                value: bugReport.withLog,
                onChanged: (bool? value) => ref
                    .read(bugReportNotifierProvider.notifier)
                    .toggleWithLog(),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                title: const Text('Including screenshot'),
                value: bugReport.withScreenshot,
                onChanged: (bool? value) => ref
                    .read(bugReportNotifierProvider.notifier)
                    .toggleWithScreenshot(),
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
                  : CustomButton(
                      onPressed: () async {
                        bool res;
                        if (bugReport.description.isEmpty) {
                          _descriptionDialog();
                          return;
                        }
                        if (bugReport.tags.isEmpty) {
                          res = await _tagsDialog();
                          if (!res) {
                            return;
                          }
                        }
                        reportBug(bugReport);
                      },
                      title: 'Submit',
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

  Future<bool> _tagsDialog() async {
    bool? res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Empty tag'),
        content: const Text('Will you submit without any tag?'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    return res!;
  }
}
