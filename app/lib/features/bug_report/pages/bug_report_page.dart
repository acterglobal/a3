import 'dart:io';

import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/bug_report/actions/submit_bug_report.dart';
import 'package:acter/features/bug_report/providers/bug_report_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::bug_report::bug_report_page');

String? _getIssueId(String url) {
  // example - https://github.com/bitfriend/acter-bugs/issues/9
  RegExp re = RegExp(r'^https:\/\/github.com\/(.*)\/(.*)\/issues\/(\d*)$');
  RegExpMatch? match = re.firstMatch(url);
  if (match != null) {
    return match.group(3);
  }
  return null;
}

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
    final lang = L10n.of(context);
    try {
      loadingNotifier.update((state) => true);
      final Map<String, String> extraFields = {};
      if (submitErrorAndStackTrace) {
        widget.error.map((error) => extraFields['error'] = error);
        widget.stack.map((stack) => extraFields['stack'] = stack);
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
      String? issueId = _getIssueId(reportUrl);
      loadingNotifier.update((state) => false);
      if (context.mounted) {
        final status =
            issueId != null
                ? lang.reportedBugSuccessful(issueId)
                : lang.thanksForReport;
        EasyLoading.showToast(status);
      }
      return true;
    } catch (e, s) {
      _log.severe('Failed to report bug', e, s);
      loadingNotifier.update((state) => false);
      if (!context.mounted) return false;
      EasyLoading.showError(
        lang.bugReportingError(e),
        duration: const Duration(seconds: 3),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    final isLoading = ref.watch(bugReporterLoadingProvider);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 350),
      child: Form(
        key: formKey,
        child: Scaffold(
          appBar: AppBar(title: Text(lang.bugReportTitle)),
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
                    hintText: lang.bugReportDescription,
                  ),
                  // required field, space allowed
                  validator:
                      (val) =>
                          val == null || val.isEmpty
                              ? lang.emptyDescription
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
                  decoration: InputDecoration(hintText: lang.description),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  key: BugReportPage.includeUserId,
                  title: Text(lang.includeUserId),
                  value: withUserId,
                  onChanged:
                      (bool? value) => setState(() {
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
                      child: Text(lang.submit),
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
        onChanged:
            (bool? value) => setState(() {
              submitErrorAndStackTrace = value ?? true;
            }),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    ];
  }

  List<Widget> renderLogOptions() {
    final lang = L10n.of(context);
    return [
      CheckboxListTile(
        key: BugReportPage.includeLog,
        title: Text(lang.includeLog),
        value: withLogFile,
        onChanged:
            (bool? value) => setState(() {
              withLogFile = value ?? true;
            }),
        controlAffinity: ListTileControlAffinity.leading,
      ),
      CheckboxListTile(
        key: BugReportPage.includePrevLog,
        title: Text(lang.includePrevLog),
        value: withPrevLogFile,
        onChanged:
            (bool? value) => setState(() {
              withPrevLogFile = value ?? true;
            }),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    ];
  }

  List<Widget> renderForScreenShot() {
    final lang = L10n.of(context);
    return widget.imagePath.map(
          (path) => [
            const SizedBox(height: 10),
            CheckboxListTile(
              key: BugReportPage.includeScreenshot,
              title: Text(lang.includeScreenshot),
              value: withScreenshot,
              onChanged:
                  (bool? value) => setState(() {
                    withScreenshot = value ?? true;
                  }),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 10),
            if (withScreenshot)
              Image.file(
                File(path),
                key: BugReportPage.screenshot,
                width: MediaQuery.of(context).size.width * 0.8,
                errorBuilder: (context, error, stackTrace) {
                  return Text(lang.couldNotLoadImage(error));
                },
              ),
            if (withScreenshot) const SizedBox(height: 10),
          ],
        ) ??
        [];
  }
}
