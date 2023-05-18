import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:acter/features/home/data/repositories/sdk_repository.dart';
import 'package:acter/features/home/states/client_state.dart';
import 'package:acter/features/news/notifiers/search_space_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Client, EventId, FfiListNewsSlide, NewsEntryDraft, NewsSlide, Space;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';

final postUpdateProvider =
    AutoDisposeAsyncNotifierProvider<PostUpdateNotifier, void>(
  () => PostUpdateNotifier(),
);

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
    NewsSlide? slide;
    if (attachmentUri == null) {
      slide = draft.newTextSlide(description);
    } else {
      String? mimeType = lookupMimeType(attachmentUri);
      if (mimeType != null) {
        if (mimeType.startsWith('image/')) {
          File image = File(attachmentUri);
          Uint8List bytes = image.readAsBytesSync();
          var decodedImage = await decodeImageFromList(bytes);
          EventId eventId = await space.sendImageMessage(
            attachmentUri,
            'Untitled Image',
            mimeType,
            bytes.length,
            decodedImage.width,
            decodedImage.height,
            null,
          );
          slide = draft.newImageSlide(
            description,
            eventId.toString(),
            mimeType,
            bytes.length,
            decodedImage.width,
            decodedImage.height,
            null,
          );
        } else if (mimeType.startsWith('audio/')) {
          File audio = File(attachmentUri);
          Uint8List bytes = audio.readAsBytesSync();
          EventId eventId = await space.sendAudioMessage(
            attachmentUri,
            'Untitled Audio',
            mimeType,
            null,
            bytes.length,
          );
          slide = draft.newAudioSlide(
            description,
            eventId.toString(),
            null,
            mimeType,
            bytes.length,
          );
        } else if (mimeType.startsWith('video/')) {
          File video = File(attachmentUri);
          Uint8List bytes = video.readAsBytesSync();
          EventId eventId = await space.sendVideoMessage(
            attachmentUri,
            'Untitled Video',
            mimeType,
            null,
            null,
            null,
            bytes.length,
            null,
          );
          slide = draft.newVideoSlide(
            description,
            eventId.toString(),
            null,
            null,
            null,
            mimeType,
            bytes.length,
            null,
          );
        }
      }
      if (slide == null) {
        File file = File(attachmentUri);
        Uint8List bytes = file.readAsBytesSync();
        EventId eventId = await space.sendFileMessage(
          attachmentUri,
          'Untitled File',
          mimeType ?? 'application/octet',
          bytes.length,
        );
        slide = draft.newFileSlide(
          description,
          eventId.toString(),
          mimeType ?? 'application/octet',
          bytes.length,
        );
      }
    }
    final sdk = ref.read(sdkRepositoryProvider);
    FfiListNewsSlide slides = sdk.createNewsSlideList();
    slides.add(slide);
    draft.slides(slides);
    var eventId = await draft.send();
    return eventId;
  }
}
