import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

Future<void> copyMessageAction(BuildContext context, String body) async {
  String msg = body.trim();
  await AppFlowyClipboard.setData(text: msg);
  if (context.mounted) {
    Navigator.pop(context);
  }
}
