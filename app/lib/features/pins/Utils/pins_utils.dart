import 'dart:async';
import 'dart:math';
import 'package:acter/features/pins/models/create_pin_state/pin_attachment_model.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::pins::utils');

Future<void> savePinTitle(
  BuildContext context,
  ActerPin pin,
  String newTitle,
) async {
  try {
    EasyLoading.show(status: L10n.of(context).updateName);
    final updateBuilder = pin.updateBuilder();
    updateBuilder.title(newTitle);
    await updateBuilder.send();
    EasyLoading.dismiss();
    if (!context.mounted) return;
    Navigator.pop(context);
  } catch (e) {
    EasyLoading.dismiss();
    if (!context.mounted) return;
    EasyLoading.showError(L10n.of(context).updateNameFailed(e));
  }
}

Future<void> savePinLink(
  BuildContext context,
  ActerPin pin,
  String newLink,
) async {
  try {
    EasyLoading.show(status: L10n.of(context).updatingLinking);
    final updateBuilder = pin.updateBuilder();
    updateBuilder.url(newLink);
    await updateBuilder.send();
    EasyLoading.dismiss();
    if (!context.mounted) return;
    Navigator.pop(context);
  } catch (e) {
    EasyLoading.dismiss();
    if (!context.mounted) return;
    EasyLoading.showError(L10n.of(context).updateNameFailed(e));
  }
}

Future<void> saveDescription(
  BuildContext context,
  String htmlBodyDescription,
  String plainDescription,
  ActerPin pin,
) async {
  try {
    EasyLoading.show(status: L10n.of(context).updatingDescription);
    final updateBuilder = pin.updateBuilder();
    updateBuilder.contentText(plainDescription);
    updateBuilder.contentHtml(plainDescription, htmlBodyDescription);
    await updateBuilder.send();
    EasyLoading.dismiss();
    if (!context.mounted) return;
    Navigator.pop(context);
  } catch (e) {
    EasyLoading.dismiss();
    if (!context.mounted) return;
    EasyLoading.showError(L10n.of(context).updateNameFailed(e));
  }
}

String getFileSize(PlatformFile file) {
  int bytes = file.size;
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
  var i = (log(bytes) / log(1024)).floor();
  return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
}

FileType attachmentFileType(PinAttachmentType pinAttachmentType) {
  switch (pinAttachmentType) {
    case PinAttachmentType.image:
      return FileType.image;
    case PinAttachmentType.video:
      return FileType.video;
    case PinAttachmentType.audio:
      return FileType.audio;
    case PinAttachmentType.file:
      return FileType.custom;
    default:
      return FileType.any;
  }
}

String documentTypeFromFileExtension(String fileExtension) {
  switch (fileExtension) {
    case 'png':
    case 'jpg':
    case 'jpeg':
      return 'Image';
    case 'mov':
    case 'mp4':
      return 'Video';
    case 'mp3':
    case 'wav':
      return 'Audio';
    case 'pdf':
      return 'PDF';
    case 'txt':
      return 'Text File';
    default:
      return '';
  }
}

//Select Attachment
Future<void> selectAttachment(
  WidgetRef ref,
  PinAttachmentType pinAttachmentType,
) async {
  try {
    final fileType = attachmentFileType(pinAttachmentType);
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: fileType,
      allowedExtensions: fileType == FileType.custom ? ['pdf', 'txt'] : null,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      String fileSize = getFileSize(file);
      final fileNameSplit = file.name.split('.');
      final title = fileNameSplit.first;
      final fileExtension = fileNameSplit.last;
      final attachment = PinAttachment(
        pinAttachmentType: pinAttachmentType,
        title: title,
        fileExtension: fileExtension,
        path: file.path,
        size: fileSize,
      );
      ref.read(createPinStateProvider.notifier).addAttachment(attachment);
    }
  } catch (e, st) {
    debugPrint('Error => $e');
    _log.severe('Error => $e', st);
  }
}
