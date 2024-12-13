import 'dart:io';
import 'dart:typed_data';

import 'package:acter/common/models/types.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show AttachmentDraft, AttachmentsManager, RefDetails;
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

final _log = Logger('a3::attachments::actions::handle_selected');

// if generic attachment, send via manager
Future<void> handleAttachmentSelected({
  required BuildContext context,
  required WidgetRef ref,
  required AttachmentsManager manager,
  required List<File> attachments,
  String? title,
  String? link,
  required AttachmentType attachmentType,
}) async {
  /// converts user selected media to attachment draft and sends state list.
  /// only supports image/video/audio/file.
  final lang = L10n.of(context);
  EasyLoading.show(status: lang.sendingAttachment);
  final client = ref.read(alwaysClientProvider);
  List<AttachmentDraft> drafts = [];
  try {
    for (final file in attachments) {
      final mimeType = lookupMimeType(file.path);
      String fileName = p.basename(file.path);
      if (mimeType == null) throw lang.failedToDetectMimeType;
      if (attachmentType == AttachmentType.camera ||
          attachmentType == AttachmentType.image) {
        Uint8List bytes = await file.readAsBytes();
        final decodedImage = await decodeImageFromList(bytes);
        final imageDraft = client
            .imageDraft(file.path, mimeType)
            .filename(title ?? fileName)
            .size(bytes.length)
            .width(decodedImage.width)
            .height(decodedImage.height);
        final attachmentDraft = await manager.contentDraft(imageDraft);
        drafts.add(attachmentDraft);
      } else if (attachmentType == AttachmentType.audio) {
        Uint8List bytes = await file.readAsBytes();
        final audioDraft = client
            .audioDraft(file.path, mimeType)
            .filename(title ?? fileName)
            .size(bytes.length);
        final attachmentDraft = await manager.contentDraft(audioDraft);
        drafts.add(attachmentDraft);
      } else if (attachmentType == AttachmentType.video) {
        Uint8List bytes = await file.readAsBytes();
        final videoDraft = client
            .videoDraft(file.path, mimeType)
            .filename(title ?? fileName)
            .size(bytes.length);
        final attachmentDraft = await manager.contentDraft(videoDraft);
        drafts.add(attachmentDraft);
      } else {
        final fileDraft = client
            .fileDraft(file.path, mimeType)
            .filename(title ?? fileName)
            .size(file.lengthSync());
        final attachmentDraft = await manager.contentDraft(fileDraft);
        drafts.add(attachmentDraft);
      }
    }
    if (attachmentType == AttachmentType.link && link != null) {
      final attachmentDraft = await manager.linkDraft(link, title);
      drafts.add(attachmentDraft);
    }
    for (final draft in drafts) {
      final res = await draft.send();
      _log.info('attachment sent: $res');
    }
    EasyLoading.dismiss();
  } catch (e, s) {
    _log.severe('Failed to create attachments', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showError(
      lang.errorSendingAttachment(e),
      duration: const Duration(seconds: 3),
    );
  }
}

// if generic attachment, send via manager
Future<void> addRefDetailAttachment({
  required BuildContext context,
  required WidgetRef ref,
  required AttachmentsManager manager,
  required RefDetails refDetails,
}) async {
  final lang = L10n.of(context);
  EasyLoading.show(status: lang.sendingAttachment);
  try {
    List<AttachmentDraft> drafts = [];
    final attachmentDraft = await manager.referenceDraft(refDetails);
    drafts.add(attachmentDraft);
    for (final draft in drafts) {
      final res = await draft.send();
      _log.info('attachment sent: $res');
    }
    EasyLoading.dismiss();
  } catch (e, s) {
    _log.severe('Failed to create attachments', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showError(
      lang.errorSendingAttachment(e),
      duration: const Duration(seconds: 3),
    );
  }
}
