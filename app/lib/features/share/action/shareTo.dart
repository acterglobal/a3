import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:acter/l10n/generated/l10n.dart';

final _log = Logger('a3::share::share_to');

Future<void> shareToWhatsApp({
  required BuildContext context,
  required String text,
}) async {
  final url = 'whatsapp://send?text=$text';
  await _shareTo(context: context, url: url);
}

Future<void> shareToTelegram({
  required BuildContext context,
  required String text,
}) async {
  final url = 'tg://msg?text=$text';
  await _shareTo(context: context, url: url);
}

Future<void> shareToSignal({
  required BuildContext context,
  required String text,
}) async {
  if (Platform.isAndroid) {
    AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.SENDTO',
      data: 'smsto:',
      package: 'org.thoughtcrime.securesms',
      arguments: {'sms_body': text},
    );
    await intent.launch();
  }
}

Future<void> _shareTo({
  required BuildContext context,
  required String url,
}) async {
  final encodedUri = Uri.parse(url);
  if (await canLaunchUrl(encodedUri)) {
    await launchUrl(encodedUri);
  } else {
    _log.warning('App not available');
    if (!context.mounted) return;
    EasyLoading.showError(
      L10n.of(context).appUnavailable,
      duration: const Duration(seconds: 3),
    );
  }
}

Future<void> shareToOnePassword({
  required BuildContext context,
  required String text,
}) async {
  final url = 'onepassword://';
  await _shareTo(context: context, url: url);
}

Future<void> shareToBitwarden({
  required BuildContext context,
  required String text,
}) async {
  final url = 'bitwarden://';
  await _shareTo(context: context, url: url);
}

Future<void> shareToKeeper({
  required BuildContext context,
  required String text,
}) async {
  final url = 'keeper://';
  await _shareTo(context: context, url: url);
}


Future<void> shareToLastPass({
  required BuildContext context,
  required String text,
}) async {
  final url = 'lastpass://';
  await _shareTo(context: context, url: url);
}

Future<void> shareToEnpass({
  required BuildContext context,
  required String text,
}) async {
  final url = 'enpass://';
  await _shareTo(context: context, url: url);
}

Future<void> shareToProtonPass({
  required BuildContext context,
  required String text,
}) async {
  final url = 'protonpass://';
  await _shareTo(context: context, url: url);
}


