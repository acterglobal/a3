import 'dart:io';

import 'package:acter/common/dialogs/attachment_confirmation.dart';
import 'package:acter/common/models/types.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/attachments/widgets/attachment_options.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show AttachmentsManager;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// reusable dialog for attachment selection
void showAttachmentSelection(
  BuildContext context,
  AttachmentsManager manager,
) async {
  isLargeScreen(context)
      ? await showAdaptiveDialog(
          context: context,
          builder: (context) => Dialog(
            child: AttachmentOptions(
              onTapImage: () => _onTapImageSelection(context, manager),
              onTapVideo: () => _onTapVideoSelection(context, manager),
              onTapFile: () => _onTapFileSelection(context, manager),
            ),
          ),
        )
      : await showModalBottomSheet(
          isDismissible: true,
          context: context,
          builder: (context) => AttachmentOptions(
            onTapCamera: () => _onTapCameraSelection(context, manager),
            onTapImage: () => _onTapImageSelection(context, manager),
            onTapVideo: () => _onTapVideoSelection(context, manager),
            onTapFile: () => _onTapFileSelection(context, manager),
          ),
        );
}

void _onTapCameraSelection(
  BuildContext context,
  AttachmentsManager manager,
) async {
  XFile? imageFile = await ImagePicker().pickImage(source: ImageSource.camera);
  if (imageFile != null) {
    File file = File(imageFile.path);

    if (context.mounted) {
      Navigator.of(context).pop();
      attachmentConfirmationDialog(
        context,
        manager,
        [(type: AttachmentType.camera, file: file)],
      );
    }
  }
}

void _onTapVideoSelection(
  BuildContext context,
  AttachmentsManager manager,
) async {
  XFile? videoFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
  List<AttachmentInfo> newAttachments = [];
  if (videoFile != null) {
    File file = File(videoFile.path);
    newAttachments.add((type: AttachmentType.video, file: file));
  }
  if (context.mounted) {
    Navigator.of(context).pop();
    attachmentConfirmationDialog(
      context,
      manager,
      newAttachments,
    );
  }
}

void _onTapImageSelection(
  BuildContext context,
  AttachmentsManager manager,
) async {
  List<XFile> imageFiles = await ImagePicker().pickMultiImage();
  List<AttachmentInfo> newAttachments = [];

  for (var imageFile in imageFiles) {
    File file = File(imageFile.path);
    newAttachments.add((type: AttachmentType.image, file: file));
  }

  if (context.mounted) {
    Navigator.of(context).pop();
    attachmentConfirmationDialog(
      context,
      manager,
      newAttachments,
    );
  }
}

// open file picker method
void _onTapFileSelection(
  BuildContext context,
  AttachmentsManager manager,
) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.any,
    allowMultiple: true,
  );
  if (result != null) {
    List<AttachmentInfo> newAttachments =
        result.paths.map<AttachmentInfo>((path) {
      var file = File(path!);
      var attachment = (type: AttachmentType.file, file: file);
      return attachment;
    }).toList();

    if (context.mounted) {
      Navigator.of(context).pop();
      attachmentConfirmationDialog(
        context,
        manager,
        newAttachments,
      );
    }
  }
}
