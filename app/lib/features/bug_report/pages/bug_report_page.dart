import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/bug_report/const.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';

final _log = Logger('a3::bug_report');

Future<String> report({
  bool withLog = false,
  bool withPrevLogFile = false,
  bool withUserId = false,
  required String description,
  String? screenshotPath,
}) async {
  final sdk = await ActerSdk.instance;

  final request = http.MultipartRequest('POST', Uri.parse(rageshakeUrl));
  request.fields.addAll({
    'text': description,
    'user_agent': userAgent,
    'app': appName, // should be same as one among github_project_mappings
    'version': versionName,
  });
  if (withUserId) {
    final client = sdk.currentClient;
    if (client != null) {
      request.fields.addAll({'UserId': client.userId().toString()});
    }
  }
  if (withLog) {
    String logFile = sdk.api.rotateLogFile();
    if (logFile.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'log',
          File(logFile).readAsBytesSync(),
          filename: basename(logFile),
          contentType: MediaType('text', 'plain'),
        ),
      );
    }
  }
  if (withPrevLogFile) {
    String? prevLogFile = sdk.previousLogPath;
    if (prevLogFile != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'log',
          File(prevLogFile).readAsBytesSync(),
          filename:
              '${basenameWithoutExtension(prevLogFile)}-${Random().nextInt(10000)}.log', // randomize to ensure the server doesn't overwrite any previous one...
          contentType: MediaType('text', 'plain'),
        ),
      );
    }
  }
  if (screenshotPath != null) {
    _log.info('sending with screenshot');
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        File(screenshotPath).readAsBytesSync(),
        filename: basename(screenshotPath),
        contentType: MediaType('image', 'png'),
      ),
    );
  }
  _log.info('sending $rageshakeUrl');
  final resp = await request.send();
  if (resp.statusCode == HttpStatus.ok) {
    Map<String, dynamic> json = jsonDecode(await resp.stream.bytesToString());
    if (screenshotPath != null) {
      await File(screenshotPath).delete();
    }
    // example - https://github.com/bitfriend/acter-bugs/issues/9
    return json['report_url'] ?? '';
  } else {
    String body = await resp.stream.bytesToString();
    _log.severe('Sending bug report failed with ${resp.statusCode}: $body');
    throw '${resp.statusCode}: $body';
  }
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

  const BugReportPage({super.key = pageKey, this.imagePath});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BugReportState();
}

class _BugReportState extends ConsumerState<BugReportPage> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  bool withScreenshot = false;
  bool withLogFile = false;
  bool withPrevLogFile = false;
  bool withUserId = false;

  Future<bool> reportBug(BuildContext context) async {
    final loadingNotifier = ref.read(loadingProvider.notifier);
    try {
      loadingNotifier.update((state) => true);
      String reportUrl = await report(
        withLog: withLogFile,
        withPrevLogFile: withPrevLogFile,
        withUserId: withUserId,
        description: titleController.text,
        screenshotPath: withScreenshot ? widget.imagePath : null,
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
    } catch (e) {
      loadingNotifier.update((state) => false);
      if (context.mounted) {
        EasyLoading.showError(
          L10n.of(context).bugReportingError(e),
          duration: const Duration(seconds: 3),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loadingProvider);
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
                Text(L10n.of(context).bugReportDescription),
                const SizedBox(height: 10),
                TextFormField(
                  key: BugReportPage.titleField,
                  controller: titleController,
                  validator: (newValue) => newValue == null || newValue.isEmpty
                      ? L10n.of(context).emptyDescription
                      : null,
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
                const SizedBox(height: 10),
                CheckboxListTile(
                  key: BugReportPage.includeScreenshot,
                  title: Text(L10n.of(context).includeScreenshot),
                  value: withScreenshot,
                  onChanged: (bool? value) => setState(() {
                    withScreenshot = value ?? true;
                  }),
                  controlAffinity: ListTileControlAffinity.leading,
                  enabled: widget.imagePath != null,
                ),
                const SizedBox(height: 10),
                if (withScreenshot)
                  Image.file(
                    File(widget.imagePath!),
                    key: BugReportPage.screenshot,
                    width: MediaQuery.of(context).size.width * 0.8,
                    errorBuilder: (
                      BuildContext ctx,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return Text(L10n.of(context).couldNotLoadImage(error));
                    },
                  ),
                if (withScreenshot) const SizedBox(height: 10),
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
                            context.pop();
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
}
