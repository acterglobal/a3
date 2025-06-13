import 'dart:io';

import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:flutter/material.dart';

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
        return ActerIcon.filePdf.data;
      case 'doc':
      case 'docx':
        return ActerIcon.fileDoc.data;
      case 'csv':
        return ActerIcon.fileCsv.data;
      case 'xls':
      case 'xlsx':
        return ActerIcon.fileXls.data;
      case 'txt':
      default:
        return ActerIcon.file.data;
    }
  }
}
