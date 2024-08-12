import 'dart:async';
import 'dart:math';
import 'package:acter/common/models/types.dart';
import 'package:acter/features/pins/models/create_pin_state/pin_attachment_model.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::pins::select::attachment');

String getFileSize(PlatformFile file) {
  int bytes = file.size;
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
  var i = (log(bytes) / log(1024)).floor();
  return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
}

FileType attachmentFileType(AttachmentType pinAttachmentType) {
  switch (pinAttachmentType) {
    case AttachmentType.image:
      return FileType.image;
    case AttachmentType.video:
      return FileType.video;
    case AttachmentType.audio:
      return FileType.audio;
    case AttachmentType.file:
      return FileType.custom;
    default:
      return FileType.any;
  }
}

String documentTypeFromFileExtension(String fileExtension) {
  switch (fileExtension) {
    case 'png':
    case 'jpg':
    case 'jpeg':
      return 'Image';
    case 'mov':
    case 'mp4':
      return 'Video';
    case 'mp3':
    case 'wav':
      return 'Audio';
    case 'pdf':
      return 'PDF';
    case 'txt':
      return 'Text File';
    default:
      return '';
  }
}

//Select Attachment
Future<void> selectAttachment(
  WidgetRef ref,
  AttachmentType attachmentType,
) async {
  try {
    final fileType = attachmentFileType(attachmentType);
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: fileType,
      allowedExtensions: fileType == FileType.custom ? ['pdf', 'txt'] : null,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      String fileSize = getFileSize(file);
      final fileNameSplit = file.name.split('.');
      final title = fileNameSplit.first;
      final fileExtension = fileNameSplit.last;
      final attachment = PinAttachment(
        attachmentType: attachmentType,
        title: title,
        fileExtension: fileExtension,
        path: file.path,
        size: fileSize,
      );
      ref.read(createPinStateProvider.notifier).addAttachment(attachment);
    }
  } catch (e, st) {
    debugPrint('Error => $e');
    _log.severe('Error => $e', st);
  }
}
