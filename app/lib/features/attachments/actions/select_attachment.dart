import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/attachments/types.dart';
import 'package:acter/features/attachments/widgets/attachment_selection_options.dart';
import 'package:flutter/material.dart';

Future<void> selectAttachment({
  required BuildContext context,
  required OnAttachmentSelected onSelected,
}) async {
  context.isLargeScreen
      ? await showAdaptiveDialog(
          context: context,
          builder: (context) => Dialog(
            child: AttachmentSelectionOptions(
              onSelected: onSelected,
            ),
          ),
        )
      : await showModalBottomSheet(
          isDismissible: true,
          context: context,
          builder: (context) => AttachmentSelectionOptions(
            onSelected: onSelected,
          ),
        );
}
