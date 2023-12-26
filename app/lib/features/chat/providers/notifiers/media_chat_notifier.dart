import 'dart:io';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/features/chat/models/media_chat_state/media_chat_state.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class MediaChatNotifier extends StateNotifier<MediaChatState> {
  final Ref ref;
  final String messageId;
  Convo? _convo;

  MediaChatNotifier({
    required this.messageId,
    required this.ref,
  }) : super(const MediaChatState()) {
    _init();
  }

  void _init() async {
    // FIXME: Remove currentConvoProvider - https://github.com/acterglobal/a3/issues/1244
    _convo = await ref.read(currentConvoProvider.future);
    if (_convo != null) {
      state = state.copyWith(
        mediaChatLoadingState: const MediaChatLoadingState.loading(),
      );
      try {
        //Get media path if already downloaded
        final mediaPath = await _convo!.mediaPath(messageId, false);
        if (mediaPath.text() != null) {
          state = state.copyWith(
            mediaFile: File(mediaPath.text()!),
            mediaChatLoadingState: const MediaChatLoadingState.loaded(),
          );
        } else {
          state = state.copyWith(
            mediaChatLoadingState: const MediaChatLoadingState.error(
              'Media not found',
            ),
          );
        }
      } catch (e) {
        state = state.copyWith(
          mediaChatLoadingState: MediaChatLoadingState.error(
            'Some error occurred ${e.toString()}',
          ),
        );
      }
    } else {
      state = state.copyWith(
        mediaChatLoadingState:
            const MediaChatLoadingState.error('Unable to load convo'),
      );
    }
  }

  Future<void> downloadMedia() async {
    if (_convo != null) {
      state = state.copyWith(isDownloading: true);

      //Download media if media path is not available
      final tempDir = await getTemporaryDirectory();
      final result = await _convo!.downloadMedia(
        messageId,
        null,
        tempDir.path,
      );
      String? mediaPath = result.text();
      if (mediaPath != null) {
        state = state.copyWith(
          mediaFile: File(mediaPath),
          isDownloading: false,
        );
      }
    }
  }
}
