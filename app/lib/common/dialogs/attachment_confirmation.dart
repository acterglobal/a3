import 'dart:io';

import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/attachments/post_attachment_selection.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show AttachmentsManager, Convo;
import 'package:flutter/material.dart';

// reusable attachment confirmation dialog
void attachmentConfirmationDialog(
  BuildContext ctx,
  AttachmentsManager? manager,
  Convo? convo,
  List<File>? selectedFiles,
) {
  if (selectedFiles != null && selectedFiles.isNotEmpty) {
    isLargeScreen(ctx)
        ? showAdaptiveDialog(
            context: ctx,
            builder: (ctx) => PostAttachmentSelection(
              files: selectedFiles,
              manager: manager,
              convo: convo,
            ),
          )
        : showModalBottomSheet(
            context: ctx,
            builder: (ctx) => PostAttachmentSelection(
              files: selectedFiles,
              manager: manager,
              convo: convo,
            ),
          );
  }
}
