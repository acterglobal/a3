import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> openLink(
  WidgetRef ref,
  String target,
  BuildContext context,
) async {
  final lang = L10n.of(context);
  return switch (ref.watch(openSystemLinkSettingsProvider)) {
    OpenSystemLinkSetting.copy => _copyToClipboard(lang, target),
    OpenSystemLinkSetting.open => await _tryOpeningLink(lang, target),
  };
}

Future<bool> _tryOpeningLink(L10n lang, String target) async {
  final Uri? url = Uri.tryParse(target);
  if (url == null) {
    EasyLoading.showError(lang.errorParsinLink);
    return false;
  }
  return await launchUrl(url);
}

bool _copyToClipboard(L10n lang, String target) {
  final data = ClipboardData(text: target);
  Clipboard.setData(data);
  EasyLoading.showToast(lang.linkCopiedToClipboard);
  return true;
}
