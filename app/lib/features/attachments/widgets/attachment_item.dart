import 'package:acter/features/attachments/widgets/attachment_container.dart';
import 'package:acter/features/attachments/widgets/views/file_view.dart';
import 'package:acter/features/attachments/widgets/views/image_view.dart';
import 'package:acter/features/attachments/widgets/views/video_view.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Attachment;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Attachment item UI
class AttachmentItem extends ConsumerWidget {
  final Attachment attachment;
  // whether item can be viewed on gesture
  final bool? openView;
  const AttachmentItem({
    super.key,
    required this.attachment,
    this.openView = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var msgContent = attachment.msgContent();
    String type = attachment.typeStr();
    if (type == 'image') {
      return AttachmentContainer(
        name: msgContent.body(),
        child: ImageView(attachment: attachment, openView: openView),
      );
    } else if (type == 'video') {
      return AttachmentContainer(
        name: msgContent.body(),
        child: VideoView(attachment: attachment, openView: openView),
      );
    } else {
      return AttachmentContainer(
        name: msgContent.body(),
        child: FileView(attachment: attachment, openView: openView),
      );
    }
  }
}
