import 'dart:convert';
import 'dart:io';

import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';

const rageshakeUrl = String.fromEnvironment(
  'RAGESHAKE_URL',
  defaultValue: 'http://localhost/api/submit',
);

class BugReportController extends GetxController {
  List<String> tags = [];
  String errorText = '';
  bool isSubmitting = false;

  void setTags(List<String> values) {
    tags = values;
  }

  Future<String?> report(
    BuildContext context,
    String description,
    bool withLog,
    String? screenshotPath,
  ) async {
    // validate issue description
    if (description.isEmpty) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) => AlertDialog(
          title: const Text('Empty description'),
          content: const Text('Please enter the issue description'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Ok'),
            ),
          ],
        ),
      );
      return '';
    }

    // validate issue tag
    if (tags.isEmpty) {
      bool? res = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) => AlertDialog(
          title: const Text('Empty tag'),
          content: const Text('Will you submit without any tag?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      if (res == false) {
        return '';
      }
    }

    isSubmitting = true;
    update(['submit']);
    final sdk = await EffektioSdk.instance;
    String logFile = sdk.rotateLogFile();

    var request = http.MultipartRequest('POST', Uri.parse(rageshakeUrl));
    request.fields.addAll({
      'text': description,
      'user_agent': userAgent,
      'app': appName, // should be same as one among github_project_mappings
      'version': versionName,
    });
    request.fields.addIf(tags.isNotEmpty, 'label', tags.join(','));
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
      // example - https://github.com/bitfriend/effektio-bugs/issues/9
      reportUrl = json['report_url'];
    }
    isSubmitting = false;
    return reportUrl;
  }
}
