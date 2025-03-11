import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:acter/config/env.g.dart';
import 'package:acter/config/setup.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';

final _log = Logger('a3::bug_report::submit_bug_report');

Future<String> submitBugReport({
  bool withLog = false,
  bool withPrevLogFile = false,
  bool withUserId = false,
  required String title,
  String? screenshotPath,
  Map<String, String> extraFields = const {},
}) async {
  final sdk = await ActerSdk.instance;

  final request = http.MultipartRequest('POST', Uri.parse(Env.rageshakeUrl));
  request.fields.addAll({
    'text': title,
    'user_agent': userAgent,
    'app':
        Env.rageshakeAppName, // should be same as one among github_project_mappings
    'version': Env.rageshakeAppVersion,
  });
  request.fields.addAll(extraFields);
  if (withUserId) {
    final client = sdk.currentClient;
    if (client != null) {
      request.fields['UserId'] = client.userId().toString();
    }
  }
  request.fields.addAll(extraFields);
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
      final basename = basenameWithoutExtension(prevLogFile);
      final suffix = Random().nextInt(10000);
      request.files.add(
        http.MultipartFile.fromBytes(
          'log',
          File(prevLogFile).readAsBytesSync(),
          // randomize to ensure the server doesn’t overwrite any previous one...
          filename: '$basename-$suffix.log',
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
  _log.info('sending ${Env.rageshakeUrl}');
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
