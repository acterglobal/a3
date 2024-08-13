import 'package:acter/common/models/types.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

Widget attachmentLeadingIcon(AttachmentType pinAttachmentType) {
  switch (pinAttachmentType) {
    case AttachmentType.link:
      return const Icon(Atlas.link);
    case AttachmentType.image:
      return const Icon(Atlas.image_gallery);
    case AttachmentType.video:
      return const Icon(Atlas.video_camera);
    case AttachmentType.audio:
      return const Icon(Atlas.audio_headphones);
    case AttachmentType.file:
      return const Icon(Atlas.file);
    default:
      return const SizedBox.shrink();
  }
}
