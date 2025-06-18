import 'dart:io';

import 'package:acter/common/models/types.dart';
import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';
import 'package:acter/l10n/generated/l10n.dart';

// upload and send file (as message) action
Future<void> attachmentUploadAction({
  required String roomId,
  required List<File> files,
  required AttachmentType attachmentType,
  required WidgetRef ref,
  required BuildContext context,
  required Logger log,
}) async {
  final lang = L10n.of(context);
  final client = await ref.read(alwaysClientProvider.future);
  final inputState = ref.read(chatInputProvider);
  final stream = await ref.read(timelineStreamProvider(roomId).future);

  try {
    for (final file in files) {
      String? mimeType = lookupMimeType(file.path);
      if (mimeType == null) throw lang.failedToDetectMimeType;
      final fileLen = file.lengthSync();
      if (mimeType.startsWith('image/') &&
          (attachmentType == AttachmentType.image ||
              attachmentType == AttachmentType.camera)) {
        final bytes = file.readAsBytesSync();
        final image = await decodeImageFromList(bytes);
        final imageDraft =
            client.imageDraft(file.path)
              ..mimetype(mimeType)
              ..size(fileLen)
              ..width(image.width)
              ..height(image.height);
        if (inputState.selectedMessageState == SelectedMessageState.replyTo) {
          final remoteId = inputState.selectedMessage?.remoteId;
          if (remoteId == null) throw 'remote id of sel msg not available';
          await stream.replyMessage(remoteId, imageDraft);
        } else {
          await stream.sendMessage(imageDraft);
        }
      } else if (mimeType.startsWith('audio/') &&
          attachmentType == AttachmentType.audio) {
        final audioDraft =
            client.audioDraft(file.path)
              ..mimetype(mimeType)
              ..size(file.lengthSync());
        if (inputState.selectedMessageState == SelectedMessageState.replyTo) {
          final remoteId = inputState.selectedMessage?.remoteId;
          if (remoteId == null) throw 'remote id of sel msg not available';
          await stream.replyMessage(remoteId, audioDraft);
        } else {
          await stream.sendMessage(audioDraft);
        }
      } else if (mimeType.startsWith('video/') &&
          attachmentType == AttachmentType.video) {
        final videoDraft =
            client.videoDraft(file.path)
              ..mimetype(mimeType)
              ..size(file.lengthSync());
        if (inputState.selectedMessageState == SelectedMessageState.replyTo) {
          final remoteId = inputState.selectedMessage?.remoteId;
          if (remoteId == null) throw 'remote id of sel msg not available';
          await stream.replyMessage(remoteId, videoDraft);
        } else {
          await stream.sendMessage(videoDraft);
        }
      } else {
        final fileDraft =
            client.fileDraft(file.path)
              ..mimetype(mimeType)
              ..size(file.lengthSync());
        if (inputState.selectedMessageState == SelectedMessageState.replyTo) {
          final remoteId = inputState.selectedMessage?.remoteId;
          if (remoteId == null) throw 'remote id of sel msg not available';
          await stream.replyMessage(remoteId, fileDraft);
        } else {
          await stream.sendMessage(fileDraft);
        }
      }
    }
  } catch (e, s) {
    log.severe('error occurred', e, s);
  }

  ref.read(chatInputProvider.notifier).unsetSelectedMessage();
}
