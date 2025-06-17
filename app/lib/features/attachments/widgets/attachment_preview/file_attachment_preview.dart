import 'dart:io';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
    return Center(child: Icon(_getIconData(file), size: iconSize));
  }

  IconData _getIconData(File file) {
    final extension = file.path.split('.').last;
    switch (extension) {
      case 'pdf':
        return PhosphorIconsRegular.filePdf;
      case 'doc':
      case 'docx':
        return PhosphorIconsRegular.fileDoc;
      case 'csv':
        return PhosphorIconsRegular.fileCsv;
      case 'xls':
      case 'xlsx':
        return PhosphorIconsRegular.fileXls;
      case 'txt':
      default:
        return PhosphorIconsRegular.file;
    }
  }
}
