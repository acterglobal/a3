import 'package:acter/common/toolkit/html/utils.dart';
import 'package:acter/common/toolkit/html_editor/services/clipboard_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';

Future<void> copyMessageAction(
  BuildContext context,
  String body,
  String? html,
) async {
  await HtmlEditorClipboardService().setFormattedText(
    html ?? minimalMarkup(body),
  );
  if (context.mounted) {
    EasyLoading.showToast(L10n.of(context).messageCopiedToClipboard);
    Navigator.pop(context);
  }
}
