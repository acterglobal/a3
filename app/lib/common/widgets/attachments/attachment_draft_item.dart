import 'dart:io';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';

// Attachment draft UI widget
class AttachmentDraftItem extends StatelessWidget {
  const AttachmentDraftItem({super.key, required this.file});
  final File file;

  @override
  Widget build(BuildContext context) {
    final containerTextStyle = Theme.of(context).textTheme.bodySmall;
    final fileName = file.path.split('/').last;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _attachmentPreview(context, file),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
          child: Text(
            fileName,
            style:
                containerTextStyle!.copyWith(overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
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
