import 'package:acter/common/models/types.dart';
import 'package:acter/features/attachments/widgets/post_attachment_selection.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show AttachmentsManager;
import 'package:flutter/material.dart';

// reusable attachment confirmation dialog
void attachmentConfirmationDialog(
  BuildContext ctx,
  AttachmentsManager manager,
  List<AttachmentInfo>? selectedAttachments,
) {
  final size = MediaQuery.of(ctx).size;
  if (selectedAttachments != null && selectedAttachments.isNotEmpty) {
    showAdaptiveDialog(
      context: ctx,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(8),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: size.width * 0.5,
            maxHeight: size.height * 0.5,
          ),
          child: PostAttachmentSelection(
            attachments: selectedAttachments,
            manager: manager,
          ),
        ),
      ),
    );
  }
}
