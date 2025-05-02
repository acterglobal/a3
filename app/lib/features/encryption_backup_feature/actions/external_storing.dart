import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

final _log = Logger('a3::encryption_backup_feature::external_storing');

Future<void> openOnePassword({
  required BuildContext context,
}) async {
  final url = 'onepassword://';
  await _open(context: context, url: url);
}

Future<void> openBitwarden({
  required BuildContext context,
}) async {
  final url = 'bitwarden://';
  await _open(context: context, url: url);
}

Future<void> openKeeper({
  required BuildContext context,
}) async {
  final url = 'keeper://';
  await _open(context: context, url: url);
}

Future<void> openLastPass({
  required BuildContext context,
}) async {
  final url = 'lastpass://';
  await _open(context: context, url: url);
}

Future<void> openEnpass({
  required BuildContext context,
}) async {
  final url = 'enpass://';
  await _open(context: context, url: url);
}

Future<void> openProtonPass({
  required BuildContext context,
}) async {
  final url = 'protonpass://';
  await _open(context: context, url: url);
}

Future<void> _open({
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
