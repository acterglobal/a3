import 'dart:io';

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/bug_report/const.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';

Future<String> report(
  bool withLog,
  String description,
  String? screenshotPath,
) async {
  final sdk = await ActerSdk.instance;

  final request = http.MultipartRequest('POST', Uri.parse(rageshakeUrl));
  request.fields.addAll({
    'text': description,
    'user_agent': userAgent,
    'app': appName, // should be same as one among github_project_mappings
    'version': versionName,
  });
  if (withLog) {
    String logFile = sdk.rotateLogFile();
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
  if (screenshotPath != null) {
    debugPrint('sending with screenshot');
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        File(screenshotPath).readAsBytesSync(),
        filename: basename(screenshotPath),
        contentType: MediaType('image', 'png'),
      ),
    );
  }
  debugPrint('sending $rageshakeUrl');
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
    throw '${resp.statusCode}: $body';
  }
}

class BugReportPage extends ConsumerStatefulWidget {
  static const titleField = Key('bug-report-title');
  static const includeScreenshot = Key('bug-report-include-screenshot');
  static const screenshot = Key('bug-report-screenshot');
  static const includeLog = Key('bug-report-include-log');
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

  Future<bool> reportBug(BuildContext context) async {
    final loadingNotifier = ref.read(loadingProvider.notifier);
    try {
      loadingNotifier.update((state) => true);
      String reportUrl = await report(
        withLogFile,
        titleController.text,
        withScreenshot ? widget.imagePath : null,
      );
      String? issueId = getIssueId(reportUrl);
      loadingNotifier.update((state) => false);
      EasyLoading.showToast(
        issueId != null
            ? 'Reported the bug successfully! (#$issueId)'
            : 'Thanks for reporting that bug!',
        toastPosition: EasyLoadingToastPosition.bottom,
      );
      return true;
    } catch (e) {
      loadingNotifier.update((state) => false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bug reporting error: $e')),
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
                  controller: titleController,
                  validator: (newValue) => newValue == null || newValue.isEmpty
                      ? ' Please enter a description'
                      : null,
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  key: BugReportPage.includeLog,
                  title: const Text('Include current logs'),
                  value: withLogFile,
                  onChanged: (bool? value) => setState(() {
                    withLogFile = value ?? true;
                  }),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  key: BugReportPage.includeScreenshot,
                  title: const Text('Include screenshot'),
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
                      return Text('Could not load image due to $error');
                    },
                  ),
                if (withScreenshot) const SizedBox(height: 10),
                const Divider(endIndent: 10, indent: 10),
                const SizedBox(height: 10),
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        key: BugReportPage.submitBtn,
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            if (await reportBug(context)) {
                              if (context.mounted && context.canPop()) {
                                context.pop();
                              }
                            }
                          }
                        },
                        child: const Text('Submit'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
