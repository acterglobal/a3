import 'dart:convert';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:http/http.dart' as http;
import 'package:enough_mail/enough_mail.dart';

const mailHogURL = String.fromEnvironment(
  'MAILHOG_URL',
  defaultValue: '',
);

extension ActerMail on ConvenientTest {
  bool hasMailSupport() {
    return mailHogURL.isNotEmpty;
  }

  Future<String> getLatestMailTo(
    String emailAddr, {
    int retry = 10,
    int delaySecs = 1,
  }) async {
    final searchUrl =
        Uri.parse('$mailHogURL/api/v2/search?kind=to&query=$emailAddr');

    for (var i = 0; i < retry; i++) {
      final resp = await http.get(searchUrl);
      assert(
        resp.statusCode == 200,
        'Error fetching $searchUrl [${resp.statusCode}]: ${resp.body}',
      );
      final decodedResponse = jsonDecode(resp.body) as Map;
      if (decodedResponse['count'] as int <= 0) {
        await Future.delayed(
          Duration(seconds: delaySecs),
          () {},
        ); // let's wait a second
        continue;
      }

      final msg = (decodedResponse['items'] as List).first as Map;
      final mime = MimeMessage.parseFromText((msg['Raw'] as Map)['Data']);
      return mime.decodeTextPlainPart()!;
    }

    throw 'No Email found after $retry retries';
  }

  Future<Uri> getLinkInLatestEmail(String emailAddr) async {
    final latestMsg = await getLatestMailTo(emailAddr);
    final lines = latestMsg.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('http')) {
        return Uri.parse(trimmed);
      }
    }
    throw 'No link found in \n$latestMsg';
  }

  Future<String> clickLinkInLatestEmail(
    String emailAddr, {
    bool replaceWithHomeserver = true,
    bool asPost = false,
  }) async {
    var link = await getLinkInLatestEmail(emailAddr);
    if (replaceWithHomeserver) {
      link = Uri.parse('$defaultServerUrl${link.path}?${link.query}');
    }
    print("Fetching $link");
    late http.Response resp;
    if (asPost) {
      resp = await http.post(link);
    } else {
      resp = await http.get(link);
    }

    assert(
      resp.statusCode == 200,
      'Error fetching $link [${resp.statusCode}]: ${resp.body}',
    );
    return resp.body;
  }
}
