import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> openLink({
  required WidgetRef ref,
  required String target,
  required L10n lang,
}) async {
  return switch (ref.read(openSystemLinkSettingsProvider)) {
    OpenSystemLinkSetting.copy => _copyToClipboard(lang, target),
    OpenSystemLinkSetting.open => await _tryOpeningLink(lang, target),
  };
}

Future<bool> openUri({
  required WidgetRef ref,
  required Uri uri,
  required L10n lang,
}) async {
  return switch (ref.read(openSystemLinkSettingsProvider)) {
    OpenSystemLinkSetting.copy => _copyToClipboard(lang, uri.toString()),
    OpenSystemLinkSetting.open => await launchUrl(uri),
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
