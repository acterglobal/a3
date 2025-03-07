import 'package:acter/common/models/types.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

Widget attachmentLeadingIcon(AttachmentType pinAttachmentType) {
  return switch (pinAttachmentType) {
    AttachmentType.link => const Icon(Atlas.link),
    AttachmentType.image => const Icon(Atlas.image_gallery),
    AttachmentType.video => const Icon(Atlas.video_camera),
    AttachmentType.audio => const Icon(Atlas.audio_headphones),
    AttachmentType.file => const Icon(Atlas.file),
    AttachmentType.camera => const Icon(Atlas.camera),
    AttachmentType.location => const Icon(Atlas.location),
  };
}
