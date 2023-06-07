import 'dart:convert';
import 'dart:io';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/bug_report/models/bug_report.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';

const rageshakeUrl = String.fromEnvironment(
  'RAGESHAKE_URL',
  defaultValue: 'https://rageshake.acter.global/api/submit',
);

class BugReportStateNotifier extends StateNotifier<BugReport> {
  final Ref ref;
  BugReportStateNotifier(this.ref)
      : super(const BugReport(description: '', tags: []));

  void setTags(List<String> tags) {
    state = state.copyWith(tags: tags);
  }

  void toggleWithLog() {
    state = state.copyWith(withLog: !state.withLog);
  }

  void toggleWithScreenshot() {
    state = state.copyWith(withScreenshot: !state.withScreenshot);
  }

  void setDescription(String description) {
    state = state.copyWith(description: description);
  }

  Future<String?> report(String? screenshotPath) async {
    ref.read(loadingProvider.notifier).update((state) => !state);
    final sdk = await ActerSdk.instance;
    String logFile = sdk.rotateLogFile();

    var request = http.MultipartRequest('POST', Uri.parse(rageshakeUrl));
    request.fields.addAll({
      'text': state.description,
      'user_agent': userAgent,
      'app': appName, // should be same as one among github_project_mappings
      'version': versionName,
    });
    request.fields.addIf(state.tags.isNotEmpty, 'label', state.tags.join(','));
    request.files.addIf(
      logFile.isNotEmpty,
      http.MultipartFile.fromBytes(
        'log',
        File(logFile).readAsBytesSync(),
        filename: basename(logFile),
        contentType: MediaType('text', 'plain'),
      ),
    );
    if (screenshotPath != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          File(screenshotPath).readAsBytesSync(),
          filename: basename(screenshotPath),
          contentType: MediaType('image', 'png'),
        ),
      );
    }
    var resp = await request.send();
    if (screenshotPath != null) {
      await File(screenshotPath).delete();
    }
    String? reportUrl;
    if (resp.statusCode == HttpStatus.ok) {
      Map<String, dynamic> json = jsonDecode(await resp.stream.bytesToString());
      // example - https://github.com/bitfriend/acter-bugs/issues/9
      reportUrl = json['report_url'];
    }
    ref.read(loadingProvider.notifier).update((state) => !state);
    return reportUrl;
  }
}
