import 'dart:io';
import 'package:acter/common/widgets/attachments/attachment_item.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';

// Attachment draft UI widget
class AttachmentDraftItem extends StatelessWidget {
  const AttachmentDraftItem({super.key, required this.file});
  final File file;

  @override
  Widget build(BuildContext context) {
    final fileName = file.path.split('/').last;
    return AttachmentContainer(
      name: fileName,
      child: _attachmentPreview(context, file),
    );
  }

  // attachment preview handler
  Widget _attachmentPreview(BuildContext context, File file) {
    final mimeType = lookupMimeType(file.path)!;
    if (mimeType.startsWith('image/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          file,
          height: 50,
          fit: BoxFit.cover,
        ),
      );
    }
    if (mimeType.startsWith('audio/')) {
      return const Icon(Atlas.file_sound_thin);
    }

    if (mimeType.startsWith('video/')) {
      return const Icon(Atlas.file_video_thin);
    } else {
      return const Icon(Atlas.plus_file_thin);
    }
  }
}
