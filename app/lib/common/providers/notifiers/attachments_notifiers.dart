import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';
import 'package:riverpod/riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::common::attachments');

// ignore_for_file: unused_field

class AttachmentsManagerNotifier
    extends FamilyNotifier<AttachmentsManager, AttachmentsManager> {
  late Stream<void> _listener;
  late StreamSubscription<void> _poller;

  @override
  AttachmentsManager build(AttachmentsManager arg) {
    _listener = arg.subscribeStream(); // keep it resident in memory
    _poller = _listener.listen(
      (e) async {
        _log.info('attempting to reload');
        final newManager = await arg.reload();
        _log.info(
          'manager updated. attachments: ${newManager.attachmentsCount()}',
        );
        state = newManager;
      },
      onError: (e, stack) {
        _log.severe('stream errored.', e, stack);
      },
      onDone: () {
        _log.info('stream ended');
      },
    );
    return arg;
  }
}

class AttachmentDraftsNotifier extends StateNotifier<List<AttachmentDraft>> {
  final AttachmentsManager manager;
  final Ref ref;

  AttachmentDraftsNotifier({required this.manager, required this.ref})
      : super([]);

  /// converts user selected media to attachment draft and sends state list.
  /// only supports image/video/audio/file.
  Future<void> sendDrafts(File file) async {
    EasyLoading.show(status: 'Sending attachments', dismissOnTap: false);
    final client = ref.read(alwaysClientProvider);
    try {
      final mimeType = lookupMimeType(file.path)!;
      if (mimeType.startsWith('image/')) {
        Uint8List bytes = await file.readAsBytes();
        final decodedImage = await decodeImageFromList(bytes);
        final imageDraft = client
            .imageDraft(file.path, mimeType)
            .size(bytes.length)
            .width(decodedImage.width)
            .height(decodedImage.height);
        final attachmentDraft = await manager.contentDraft(imageDraft);
        state = [...state, attachmentDraft];
      } else if (mimeType.startsWith('audio/')) {
        Uint8List bytes = await file.readAsBytes();
        final audioDraft =
            client.audioDraft(file.path, mimeType).size(bytes.length);
        final attachmentDraft = await manager.contentDraft(audioDraft);
        state = [...state, attachmentDraft];
      } else if (mimeType.startsWith('video/')) {
        Uint8List bytes = await file.readAsBytes();
        final videoDraft =
            client.videoDraft(file.path, mimeType).size(bytes.length);
        final attachmentDraft = await manager.contentDraft(videoDraft);
        state = [...state, attachmentDraft];
      } else {
        String fileName = file.path.split('/').last;
        final fileDraft = client
            .fileDraft(file.path, mimeType)
            .filename(fileName)
            .size(file.lengthSync());
        final attachmentDraft = await manager.contentDraft(fileDraft);
        state = [...state, attachmentDraft];
      }
      for (var draft in state) {
        final res = await draft.send();
        _log.info('attachment sent: $res');
        EasyLoading.dismiss();
      }
      // reset the selection
      resetDrafts();
    } catch (e) {
      _log.severe('failed to make attachment draft', e);
    }
  }

  /// reset the selection of attachment drafts
  void resetDrafts() => state = [];
}
