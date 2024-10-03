import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:path/path.dart';

Future<bool> downloadFile(BuildContext context, File file) async {
  final lang = L10n.of(context);
  final filename = basename(file.path);
  String? outputFile = await FilePicker.platform.saveFile(
    dialogTitle: lang.downloadFileDialogTitle,
    fileName: filename,
  );
  if (outputFile == null) return false;
  await file.copy(outputFile);
  EasyLoading.showToast(lang.downloadFileSuccess(outputFile));
  return true;
}
