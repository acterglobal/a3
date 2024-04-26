import 'dart:io';

import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/features/chat/models/media_chat_state/media_chat_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod/riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

final _log = Logger('a3::chat::media_chat_notifier');

class MediaChatNotifier extends StateNotifier<MediaChatState> {
  final Ref ref;
  final ChatMessageInfo messageInfo;
  Convo? _convo;

  MediaChatNotifier({
    required this.messageInfo,
    required this.ref,
  }) : super(const MediaChatState()) {
    _init();
  }

  void _init() async {
    _convo = await ref.read(chatProvider(messageInfo.roomId).future);
    if (_convo != null) {
      state = state.copyWith(
        mediaChatLoadingState: const MediaChatLoadingState.notYetStarted(),
      );
      try {
        //Get media path if already downloaded
        final mediaPath = await _convo!.mediaPath(messageInfo.messageId, false);
        if (mediaPath.text() != null) {
          final videoThumbnailFile = await getThumbnailData(mediaPath.text()!);
          state = state.copyWith(
            mediaFile: File(mediaPath.text()!),
            videoThumbnailFile: videoThumbnailFile,
            mediaChatLoadingState: const MediaChatLoadingState.loaded(),
          );
        } else {
          // FIXME: this does not react if yet if we switched the network ...
          if (await ref
              .read(autoDownloadMediaProvider(messageInfo.roomId).future)) {
            await downloadMedia();
          } else {
            state = state.copyWith(
              mediaChatLoadingState:
                  const MediaChatLoadingState.notYetStarted(),
            );
          }
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
      try {
        //Download media if media path is not available
        final tempDir = await getTemporaryDirectory();
        final result = await _convo!.downloadMedia(
          messageInfo.messageId,
          null,
          tempDir.path,
        );
        String? mediaPath = result.text();
        if (mediaPath != null) {
          final videoThumbnailFile = await getThumbnailData(mediaPath);
          state = state.copyWith(
            mediaFile: File(mediaPath),
            videoThumbnailFile: videoThumbnailFile,
            isDownloading: false,
          );
        }
      } catch (error, stackTrace) {
        _log.severe('Error downloading media:', error, stackTrace);
        state = state.copyWith(
          isDownloading: false,
          mediaChatLoadingState: MediaChatLoadingState.error(
            'Some error occurred ${error.toString()}',
          ),
        );
      }
    }
  }

  //FIXME : This is temporarily solution for media thumb management which lead to security issue.
  // Reference https://github.com/acterglobal/a3/issues/1586
  // Reference https://github.com/acterglobal/a3/issues/1250
  static Future<File?> getThumbnailData(String mediaPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final videoName = mediaPath.split('/').last.split('.').first;
      final destPath = p.join(tempDir.path, '$videoName.jpg');
      final destFile = File(destPath);

      if (await destFile.exists()) {
        return destFile;
      }

      final thumbnailGenerated =
          await FcNativeVideoThumbnail().getVideoThumbnail(
        srcFile: mediaPath,
        destFile: destPath,
        width: 300,
        height: 300,
        keepAspectRatio: true,
        format: 'jpeg',
        quality: 90,
      );

      if (thumbnailGenerated) {
        return destFile;
      }
    } catch (err, s) {
      // Handle platform errors.
      _log.severe('Error', err, s);
    }
    return null;
  }
}
