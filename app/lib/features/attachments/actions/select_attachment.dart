import 'package:acter/common/dialogs/bottom_sheet_container_widget.dart';
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
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    context: context,
    builder:
        (context) => BottomSheetContainerWidget(
          child: AttachmentSelectionOptions(
            onSelected: onSelected,
            onLinkSelected: onLinkSelected,
          ),
        ),
  );
}
