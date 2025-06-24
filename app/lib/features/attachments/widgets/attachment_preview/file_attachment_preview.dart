import 'dart:io';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:path/path.dart' as path;

class FileAttachmentPreview extends StatelessWidget {
  final File file;
  final double iconSize;

  const FileAttachmentPreview({
    super.key,
    required this.file,
    this.iconSize = 200,
  });

  @override
  Widget build(BuildContext context) {
    final extension = path.extension(file.path).toLowerCase();

    final IconData iconData = switch (extension) {
      '.pdf' => PhosphorIconsRegular.filePdf,
      '.doc' || '.docx' => PhosphorIconsRegular.fileDoc,
      '.csv' => PhosphorIconsRegular.fileCsv,
      '.xls' || '.xlsx' => PhosphorIconsRegular.fileXls,
      '.txt' => PhosphorIconsRegular.file,
      _ => PhosphorIconsRegular.file,
    };

    return Center(child: Icon(iconData, size: iconSize));
  }
}
