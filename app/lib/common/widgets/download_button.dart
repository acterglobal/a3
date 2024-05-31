import 'dart:io';
import 'package:path/path.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

Future<void> downloadFile(BuildContext context, File file) async {
  final lang = L10n.of(context);
  final filename = basename(file.path);
  String? outputFile = await FilePicker.platform.saveFile(
    dialogTitle: lang.downloadFileDialogTitle,
    fileName: filename,
  );

  if (outputFile != null) {
    await file.copy(outputFile);
    EasyLoading.showToast(lang.downloadFileSuccess(outputFile));
  }
}

class DownloadButton extends StatelessWidget {
  final File file;

  const DownloadButton({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      // Saving unfortunately crashes on Android at the moment
      // FIXME: https://github.com/acterglobal/a3/issues/1803
      return const SizedBox.shrink();
    }
    return IconButton(
      onPressed: () => downloadFile(context, file),
      icon: const Icon(Icons.download_rounded),
    );
  }
}
