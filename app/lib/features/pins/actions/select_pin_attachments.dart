import 'dart:async';

import 'package:acter/common/models/types.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/pins/models/create_pin_state/pin_attachment_model.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

final _log = Logger('a3::pins::select::attachment');

FileType attachmentFileType(AttachmentType pinAttachmentType) {
  return switch (pinAttachmentType) {
    AttachmentType.image => FileType.image,
    AttachmentType.video => FileType.video,
    AttachmentType.audio => FileType.audio,
    _ => FileType.any
  };
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
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      String fileSize = getHumanReadableFileSize(file.size);
      final title = p.basenameWithoutExtension(file.name);
      final fileExtension = p.extension(file.name);
      final attachment = PinAttachment(
        attachmentType: attachmentType,
        title: title,
        fileExtension: fileExtension,
        path: file.path,
        size: fileSize,
      );
      ref.read(createPinStateProvider.notifier).addAttachment(attachment);
    }
  } catch (e, s) {
    debugPrint('Error => $e');
    _log.severe('Failed to select attachment', e, s);
  }
}
