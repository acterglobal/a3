import 'dart:async';
import 'package:acter/common/models/types.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/pins/models/create_pin_state/pin_attachment_model.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::pins::select::attachment');

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
      String fileSize = getFileSize(file.size);
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
