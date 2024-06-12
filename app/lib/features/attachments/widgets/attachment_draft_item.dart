import 'package:acter/common/models/types.dart';
import 'package:acter/features/attachments/widgets/attachment_container.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

// Attachment draft UI widget
class AttachmentDraftItem extends StatelessWidget {
  const AttachmentDraftItem({super.key, required this.attachmentDraft});
  final AttachmentInfo attachmentDraft;

  @override
  Widget build(BuildContext context) {
    final fileName = attachmentDraft.file.path.split('/').last;
    return AttachmentContainer(
      name: fileName,
      child: _attachmentPreview(context, attachmentDraft),
    );
  }

  // attachment preview handler
  Widget _attachmentPreview(
    BuildContext context,
    AttachmentInfo attachmentDraft,
  ) {
    final type = attachmentDraft.type;
    if (type == AttachmentType.camera || type == AttachmentType.image) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          attachmentDraft.file,
          height: 50,
          fit: BoxFit.cover,
        ),
      );
    } else if (type == AttachmentType.video) {
      return const Icon(Atlas.file_video_thin);
    } else {
      return const Icon(Atlas.plus_file_thin);
    }
  }
}
