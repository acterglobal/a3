import 'dart:io';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/widgets/attachment_options.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

typedef PinAttachment = ({AttachmentType type, File file});

class PinUtils {
  // attachment selection sheet
  static void showAttachmentSelection(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showModalBottomSheet<void>(
      isDismissible: true,
      context: context,
      builder: (context) => AttachmentOptions(
        onTapCamera: () async {
          XFile? imageFile =
              await ImagePicker().pickImage(source: ImageSource.camera);
          if (imageFile != null) {
            File file = File(imageFile.path);
            List<PinAttachment> attachmentList = [
              (type: AttachmentType.camera, file: file),
            ];
            ref
                .read(selectedAttachmentsProvider.notifier)
                .update((state) => [...attachmentList]);
          }
        },
        onTapImage: () async {
          List<XFile> imageFiles = await ImagePicker().pickMultiImage();
          List<PinAttachment> newAttachments = [];

          for (var imageFile in imageFiles) {
            File file = File(imageFile.path);
            PinAttachment attachment = (type: AttachmentType.image, file: file);
            newAttachments.add(attachment);
          }

          List<PinAttachment> attachments =
              ref.read(selectedAttachmentsProvider);
          var attachmentNotifier =
              ref.read(selectedAttachmentsProvider.notifier);
          if (attachments.isNotEmpty) {
            attachments.addAll(newAttachments);
            attachmentNotifier.update((state) => attachments);
          } else {
            attachmentNotifier.update((state) => newAttachments);
          }
        },
        onTapVideo: () async {
          XFile? videoFile =
              await ImagePicker().pickVideo(source: ImageSource.gallery);
          List<PinAttachment> newAttachments = [];
          if (videoFile != null) {
            File file = File(videoFile.path);
            newAttachments.add((type: AttachmentType.video, file: file));
          }
          List<PinAttachment> attachments =
              ref.read(selectedAttachmentsProvider);
          var attachmentNotifier =
              ref.read(selectedAttachmentsProvider.notifier);
          if (attachments.isNotEmpty) {
            attachments.addAll(newAttachments);
            attachmentNotifier.update((state) => attachments);
          } else {
            attachmentNotifier.update((state) => newAttachments);
          }
        },
        onTapFile: () async {
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.any,
            allowMultiple: true,
          );
          if (result != null) {
            List<PinAttachment> newAttachments =
                result.paths.map<PinAttachment>((path) {
              var file = File(path!);
              var pinAttachment = (type: AttachmentType.file, file: file);
              return pinAttachment;
            }).toList();

            List<PinAttachment> attachments =
                ref.read(selectedAttachmentsProvider);
            var attachmentNotifier =
                ref.read(selectedAttachmentsProvider.notifier);
            if (attachments.isNotEmpty) {
              attachments.addAll(newAttachments);
              attachmentNotifier.update((state) => attachments);
            } else {
              attachmentNotifier.update((state) => newAttachments);
            }
          }
        },
      ),
    );
  }
}
