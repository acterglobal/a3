import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::share::share_to_whatsapp');

Future<void> shareToWhatsApp(
  BuildContext context, {
  required String text,
}) async {
  final url = 'whatsapp://send?text=$text';
  final encodedUri = Uri.parse(url);
  if (await canLaunchUrl(encodedUri)) {
    await launchUrl(encodedUri);
  } else {
    _log.warning('WhatsApp not available');
    if (!context.mounted) return;
    EasyLoading.showError(
      L10n.of(context).appUnavailable,
      duration: const Duration(seconds: 3),
    );
  }
}
