import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

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
  final url = 'sgnl://signal.me/send?text=$text';
  await _shareTo(context: context, url: url);
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
