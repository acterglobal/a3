import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Client, EventId, NewsEntryDraft, SendImageResponse, Space;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';

class PostUpdateNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // nothing to do
  }

  Future<EventId> postUpdate(String? attachmentUri, String description) async {
    Client client = ref.read(clientProvider)!;
    String spaceId = ref.read(selectedSpaceProvider.notifier).state!.roomId;
    Space space = await client.getSpace(spaceId);
    NewsEntryDraft draft = space.newsDraft();
    if (attachmentUri == null) {
      draft.addTextSlide(description);
    } else {
      String? mimeType = lookupMimeType(attachmentUri);
      bool unknownType = true;
      if (mimeType != null) {
        if (mimeType.startsWith('image/')) {
          SendImageResponse resp = await space.sendImageMessage(
            attachmentUri,
            'Untitled Image',
            null,
          );
          draft.addImageSlide(
            description,
            resp.eventId().toString(),
            mimeType,
            resp.fileSize(),
            resp.width(),
            resp.height(),
            null,
          );
          unknownType = false;
        } else if (mimeType.startsWith('audio/')) {
          File audio = File(attachmentUri);
          Uint8List bytes = audio.readAsBytesSync();
          EventId eventId = await space.sendAudioMessage(
            attachmentUri,
            'Untitled Audio',
            null,
          );
          draft.addAudioSlide(
            description,
            eventId.toString(),
            null,
            mimeType,
            bytes.length,
          );
          unknownType = false;
        } else if (mimeType.startsWith('video/')) {
          File video = File(attachmentUri);
          Uint8List bytes = video.readAsBytesSync();
          EventId eventId = await space.sendVideoMessage(
            attachmentUri,
            'Untitled Video',
            null,
            null,
            null,
            null,
          );
          draft.addVideoSlide(
            description,
            eventId.toString(),
            null,
            null,
            null,
            mimeType,
            bytes.length,
            null,
          );
          unknownType = false;
        }
      }
      if (unknownType) {
        File file = File(attachmentUri);
        Uint8List bytes = file.readAsBytesSync();
        EventId eventId = await space.sendFileMessage(
          attachmentUri,
          'Untitled File',
        );
        draft.addFileSlide(
          description,
          eventId.toString(),
          mimeType ?? 'application/octet',
          bytes.length,
        );
      }
    }
    var eventId = await draft.send();
    return eventId;
  }
}
