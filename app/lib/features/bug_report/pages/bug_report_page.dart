import 'dart:io';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/bug_report/actions/submit_bug_report.dart';
import 'package:acter/features/bug_report/providers/bug_report_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::bug_report');

class BugReportPage extends ConsumerStatefulWidget {
  static const titleField = Key('bug-report-title');
  static const includeScreenshot = Key('bug-report-include-screenshot');
  static const screenshot = Key('bug-report-screenshot');
  static const includeLog = Key('bug-report-include-log');
  static const includePrevLog = Key('bug-report-include-prev-log');
  static const includeUserId = Key('bug-report-include-user-id');
  static const submitBtn = Key('bug-report-submit');
  static const pageKey = Key('bug-report');
  final String? imagePath;
  final String? error;
  final String? stack;

  const BugReportPage({
    super.key = pageKey,
    this.imagePath,
    this.error,
    this.stack,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BugReportState();
}

class _BugReportState extends ConsumerState<BugReportPage> {
  final formKey = GlobalKey<FormState>(debugLabel: 'Bug report form key');
  final titleController = TextEditingController();
  final descController = TextEditingController();
  bool withScreenshot = false;
  bool withLogFile = false;
  bool withPrevLogFile = false;
  bool withUserId = false;
  bool submitErrorAndStackTrace = true;

  Future<bool> reportBug(BuildContext context) async {
    final loadingNotifier = ref.read(bugReporterLoadingProvider.notifier);
    try {
      loadingNotifier.update((state) => true);
      final Map<String, String> extraFields = {};
      if (submitErrorAndStackTrace) {
        if (widget.error != null) {
          extraFields['error'] = widget.error.toString();
        }
        if (widget.stack != null) {
          extraFields['stack'] = widget.stack.toString();
        }
      }
      if (descController.text.isNotEmpty) {
        extraFields['description'] = descController.text;
      }
      String reportUrl = await submitBugReport(
        withLog: withLogFile,
        withPrevLogFile: withPrevLogFile,
        withUserId: withUserId,
        title: titleController.text,
        screenshotPath: withScreenshot ? widget.imagePath : null,
        extraFields: extraFields,
      );
      String? issueId = getIssueId(reportUrl);
      loadingNotifier.update((state) => false);
      if (context.mounted) {
        final status = issueId != null
            ? L10n.of(context).reportedBugSuccessful(issueId)
            : L10n.of(context).thanksForReport;
        EasyLoading.showToast(status);
      }
      return true;
    } catch (e, s) {
      _log.severe('Failed to report bug', e, s);
      loadingNotifier.update((state) => false);
      if (!context.mounted) return false;
      EasyLoading.showError(
        L10n.of(context).bugReportingError(e),
        duration: const Duration(seconds: 3),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(bugReporterLoadingProvider);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 350),
      child: Form(
        key: formKey,
        child: Scaffold(
          appBar: AppBar(title: Text(L10n.of(context).bugReportTitle)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                TextFormField(
                  key: BugReportPage.titleField,
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: L10n.of(context).bugReportDescription,
                  ),
                  // required field, space allowed
                  validator: (val) => val == null || val.isEmpty
                      ? L10n.of(context).emptyDescription
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  controller: descController,
                  minLines: 4,
                  autofocus: true,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: L10n.of(context).description,
                  ),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  key: BugReportPage.includeUserId,
                  title: Text(L10n.of(context).includeUserId),
                  value: withUserId,
                  onChanged: (bool? value) => setState(() {
                    withUserId = value ?? true;
                  }),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const Divider(endIndent: 10, indent: 10),
                ...renderErrorOptions(),
                ...renderLogOptions(),
                ...renderForScreenShot(),
                const Divider(endIndent: 10, indent: 10),
                const SizedBox(height: 10),
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ActerPrimaryActionButton(
                        key: BugReportPage.submitBtn,
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          if (!await reportBug(context)) return;
                          if (!context.mounted) return;
                          if (context.canPop()) {
                            Navigator.pop(context);
                          }
                        },
                        child: Text(L10n.of(context).submit),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> renderErrorOptions() {
    if (widget.error == null) return [];
    return [
      CheckboxListTile(
        title: Text(L10n.of(context).includeErrorAndStackTrace),
        value: submitErrorAndStackTrace,
        onChanged: (bool? value) => setState(() {
          submitErrorAndStackTrace = value ?? true;
        }),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    ];
  }

  List<Widget> renderLogOptions() {
    return [
      CheckboxListTile(
        key: BugReportPage.includeLog,
        title: Text(L10n.of(context).includeLog),
        value: withLogFile,
        onChanged: (bool? value) => setState(() {
          withLogFile = value ?? true;
        }),
        controlAffinity: ListTileControlAffinity.leading,
      ),
      CheckboxListTile(
        key: BugReportPage.includePrevLog,
        title: Text(L10n.of(context).includePrevLog),
        value: withPrevLogFile,
        onChanged: (bool? value) => setState(() {
          withPrevLogFile = value ?? true;
        }),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    ];
  }

  List<Widget> renderForScreenShot() {
    if (widget.imagePath == null) return [];
    return [
      const SizedBox(height: 10),
      CheckboxListTile(
        key: BugReportPage.includeScreenshot,
        title: Text(L10n.of(context).includeScreenshot),
        value: withScreenshot,
        onChanged: (bool? value) => setState(() {
          withScreenshot = value ?? true;
        }),
        controlAffinity: ListTileControlAffinity.leading,
      ),
      const SizedBox(height: 10),
      if (withScreenshot)
        Image.file(
          File(widget.imagePath!),
          key: BugReportPage.screenshot,
          width: MediaQuery.of(context).size.width * 0.8,
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) {
            return Text(L10n.of(context).couldNotLoadImage(error));
          },
        ),
      if (withScreenshot) const SizedBox(height: 10),
    ];
  }
}
