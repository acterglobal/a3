import 'package:acter/features/attachments/types.dart';
import 'package:acter/features/attachments/widgets/attachment_selection_options.dart';
import 'package:flutter/material.dart';

Future<void> selectAttachment({
  required BuildContext context,
  required OnAttachmentSelected onSelected,
  OnLinkSelected? onLinkSelected,
}) async {
  await showModalBottomSheet(
    isDismissible: true,
    showDragHandle: true,
    context: context,
    builder:
        (context) => AttachmentSelectionOptions(
          onSelected: onSelected,
          onLinkSelected: onLinkSelected,
        ),
  );
}
