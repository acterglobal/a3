import 'dart:convert';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:acter/features/settings/widgets/email_address_card.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:http/http.dart' as http;
import 'package:enough_mail/enough_mail.dart';

import 'util.dart';

const mailHogURL = String.fromEnvironment(
  'MAILHOG_URL',
  defaultValue: '',
);

extension ActerMail on ConvenientTest {
  bool hasMailSupport() {
    return mailHogURL.isNotEmpty;
  }

  Future<void> confirmEmailAdd(String emailAddr, String currentUserPw) async {
    // also confirm client side or it won't work
    await find.byKey(Keys.mainNav).should(findsOneWidget);
    await navigateTo([
      MainNavKeys.quickJump,
      QuickJumpKeys.settings,
      SettingsMenu.emailAddresses,
    ]);

    final emailAddrConfirm =
        find.byKey(Key('$emailAddr-already-confirmed-btn'));
    await tester.ensureVisible(emailAddrConfirm);
    await emailAddrConfirm.should(findsOneWidget);
    await emailAddrConfirm.tap();

    final pwTextField = find.byKey(PasswordConfirm.passwordConfirmTxt);
    await pwTextField.should(findsOneWidget);
    await pwTextField.replaceText(currentUserPw);

    final pwTextBtn = find.byKey(PasswordConfirm.passwordConfirmBtn);
    await pwTextBtn.should(findsOneWidget);
    await pwTextBtn.tap();
  }

  Future<String> getLatestMailTo(
    String emailAddr, {
    int retry = 10,
    int delaySecs = 1,
    String? contains,
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

      final items = decodedResponse['items'] as List;
      for (final item in items) {
        final msg = item as Map;
        if (contains != null) {
          final subject =
              ((item['Content'] as Map)['Headers'] as Map)['Subject'].first;
          if (!subject.contains(contains)) {
            print('Skipping email $subject');
            continue;
          }
        }
        final mime = MimeMessage.parseFromText((msg['Raw'] as Map)['Data']);
        return mime.decodeTextPlainPart()!;
      }

      await Future.delayed(
        Duration(seconds: delaySecs),
        () {},
      ); // let's wait a second
    }

    throw 'No Email found after $retry retries';
  }

  Future<Uri> getLinkInLatestEmail(String emailAddr, {String? contains}) async {
    final latestMsg = await getLatestMailTo(emailAddr, contains: contains);
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
    String? contains,
  }) async {
    var link = await getLinkInLatestEmail(emailAddr, contains: contains);
    if (replaceWithHomeserver) {
      final homeserver = Uri.parse(defaultServerUrl);
      print('updating with $homeserver');
      link = link.replace(
        scheme: homeserver.scheme,
        host: homeserver.host,
        port: homeserver.port,
      );
    }
    print('Fetching $link');
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
