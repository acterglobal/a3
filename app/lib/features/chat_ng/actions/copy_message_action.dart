import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/l10n.dart';

Future<void> copyMessageAction(BuildContext context, String body) async {
  String msg = body.trim();
  await Clipboard.setData(ClipboardData(text: msg));
  if (context.mounted) {
    EasyLoading.showToast(L10n.of(context).messageCopiedToClipboard);
    Navigator.pop(context);
  }
}
