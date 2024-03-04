import 'dart:io';
import 'dart:typed_data';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/attachment_options.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

typedef PinAttachment = ({AttachmentType type, File file});

class PinUtils {
  // belongs separately, useful for showing file picker directly (desktop)
  static void _onTapFileSelection(WidgetRef ref) async {
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
          ref.read(selectedPinAttachmentsProvider);
      var attachmentNotifier =
          ref.read(selectedPinAttachmentsProvider.notifier);
      if (attachments.isNotEmpty) {
        attachments.addAll(newAttachments);
        attachmentNotifier.update((state) => [...attachments]);
      } else {
        attachmentNotifier.update((state) => newAttachments);
      }
    }
  }

  // attachment selection sheet
  static void showAttachmentSelection(
    BuildContext context,
    WidgetRef ref,
  ) async {
    isLargeScreen(context)
        ? _onTapFileSelection(ref)
        : await showModalBottomSheet(
            isDismissible: true,
            context: context,
            builder: (context) => AttachmentOptions(
              onTapCamera: () async {
                XFile? imageFile =
                    await ImagePicker().pickImage(source: ImageSource.camera);
                if (imageFile != null) {
                  File file = File(imageFile.path);
                  PinAttachment attachment =
                      (type: AttachmentType.camera, file: file);
                  ref
                      .read(selectedPinAttachmentsProvider.notifier)
                      .update((state) => [...state, attachment]);
                }
              },
              onTapImage: () async {
                List<XFile> imageFiles = await ImagePicker().pickMultiImage();
                List<PinAttachment> newAttachments = [];

                for (var imageFile in imageFiles) {
                  File file = File(imageFile.path);
                  PinAttachment attachment =
                      (type: AttachmentType.image, file: file);
                  newAttachments.add(attachment);
                }

                List<PinAttachment> attachments =
                    ref.read(selectedPinAttachmentsProvider);
                var attachmentNotifier =
                    ref.read(selectedPinAttachmentsProvider.notifier);
                if (attachments.isNotEmpty) {
                  attachments.addAll(newAttachments);
                  attachmentNotifier.update((state) => [...attachments]);
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
                    ref.read(selectedPinAttachmentsProvider);
                var attachmentNotifier =
                    ref.read(selectedPinAttachmentsProvider.notifier);
                if (attachments.isNotEmpty) {
                  attachments.addAll(newAttachments);
                  attachmentNotifier.update((state) => [...attachments]);
                } else {
                  attachmentNotifier.update((state) => newAttachments);
                }
              },
              onTapFile: () async {
                _onTapFileSelection(ref);
              },
            ),
          );
  }

  // construct message content draft and make attachment draft
  static Future<List<AttachmentDraft>?> makeAttachmentDrafts(
    Client client,
    AttachmentsManager manager,
    List<PinAttachment> attachments,
  ) async {
    List<AttachmentDraft> drafts = [];
    for (final attachment in attachments) {
      if (attachment.type == AttachmentType.camera ||
          attachment.type == AttachmentType.image) {
        final file = attachment.file;
        final String? mimeType = lookupMimeType(file.path);
        if (mimeType == null) {
          return null;
        }
        if (!mimeType.startsWith('image/')) {
          return null;
        }
        Uint8List bytes = await file.readAsBytes();
        final decodedImage = await decodeImageFromList(bytes);
        final imageDraft = client
            .imageDraft(file.path, mimeType)
            .size(bytes.length)
            .width(decodedImage.width)
            .height(decodedImage.height);
        final attachmentDraft = await manager.contentDraft(imageDraft);
        drafts.add(attachmentDraft);
      } else if (attachment.type == AttachmentType.video) {
        final file = attachment.file;
        final String? mimeType = lookupMimeType(file.path);
        if (mimeType == null) {
          return null;
        }
        if (!mimeType.startsWith('video/')) {
          return null;
        }
        Uint8List bytes = await file.readAsBytes();
        final videoDraft =
            client.videoDraft(file.path, mimeType).size(bytes.length);
        final attachmentDraft = await manager.contentDraft(videoDraft);
        drafts.add(attachmentDraft);
      } else if (attachment.type == AttachmentType.audio) {
        return null;
      } else {
        final file = attachment.file;
        String fileName = file.path.split('/').last;
        final String? mimeType = lookupMimeType(file.path);
        if (mimeType == null) {
          return null;
        }
        final fileDraft = client
            .fileDraft(file.path, mimeType)
            .filename(fileName)
            .size(file.lengthSync());
        final attachmentDraft = await manager.contentDraft(fileDraft);
        drafts.add(attachmentDraft);
      }
    }
    return drafts;
  }
}
