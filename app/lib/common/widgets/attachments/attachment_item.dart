import 'package:acter/common/widgets/attachments/attachment_container.dart';
import 'package:acter/common/widgets/attachments/views/file_view.dart';
import 'package:acter/common/widgets/attachments/views/image_view.dart';
import 'package:acter/common/widgets/attachments/views/video_view.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Attachment;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Attachment item UI
class AttachmentItem extends ConsumerWidget {
  final Attachment attachment;
  const AttachmentItem({
    super.key,
    required this.attachment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var msgContent = attachment.msgContent();
    String type = attachment.typeStr();
    if (type == 'image') {
      return AttachmentContainer(
        name: msgContent.body(),
        child: ImageView(attachment: attachment),
      );
    } else if (type == 'video') {
      return AttachmentContainer(
        name: msgContent.body(),
        child: VideoView(attachment: attachment),
      );
    } else {
      return AttachmentContainer(
        name: msgContent.body(),
        child: FileView(attachment: attachment),
      );
    }
  }
}
