import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

Future<bool> downloadFile(BuildContext context, File file) async {
  final lang = L10n.of(context);
  final filename = p.basename(file.path);
  final extension = p.extension(filename);
  String? outputFile = await FilePicker.platform.saveFile(
    dialogTitle: lang.downloadFileDialogTitle,
    fileName: filename,
  );

  if (outputFile == null) {
    return false;
  }

  if (p.extension(outputFile).isEmpty) {
    // the new file doesn't have an extension, we add the previous one again
    outputFile = '$outputFile$extension';
  }

  await file.copy(outputFile);
  EasyLoading.showToast(lang.downloadFileSuccess(outputFile));
  return true;
}
