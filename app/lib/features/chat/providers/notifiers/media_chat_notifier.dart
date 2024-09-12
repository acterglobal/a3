import 'dart:io';

import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/features/chat/models/media_chat_state/media_chat_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:extension_nullable/extension_nullable.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod/riverpod.dart';

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
    final convo = await ref.read(chatProvider(messageInfo.roomId).future);
    if (convo == null) {
      state = state.copyWith(
        mediaChatLoadingState:
            const MediaChatLoadingState.error('Unable to load convo'),
      );
      return;
    }
    _convo = convo;
    state = state.copyWith(
      mediaChatLoadingState: const MediaChatLoadingState.notYetStarted(),
    );
    try {
      //Get media path if already downloaded
      final mediaPath =
          (await convo.mediaPath(messageInfo.messageId, false)).text();

      if (mediaPath != null) {
        state = state.copyWith(
          mediaFile: File(mediaPath),
          videoThumbnailFile: null,
          mediaChatLoadingState: const MediaChatLoadingState.loaded(),
        );
        final videoThumbnailFile = await getThumbnailData(mediaPath);
        if (videoThumbnailFile != null) {
          if (state.mediaFile?.path == mediaPath) {
            state = state.copyWith(videoThumbnailFile: videoThumbnailFile);
          }
        }
      } else {
        // FIXME: this does not react if yet if we switched the network ...
        final isAutoDownload = await ref
            .read(autoDownloadMediaProvider(messageInfo.roomId).future);
        if (isAutoDownload) {
          await downloadMedia();
        } else {
          state = state.copyWith(
            mediaChatLoadingState: const MediaChatLoadingState.notYetStarted(),
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
  }

  Future<void> downloadMedia() async {
    final convo = _convo;
    if (convo == null) return;
    state = state.copyWith(isDownloading: true);
    try {
      //Download media if media path is not available
      final tempDir = await getTemporaryDirectory();
      final result = await convo.downloadMedia(
        messageInfo.messageId,
        null,
        tempDir.path,
      );
      final mediaPath = result.text();
      if (mediaPath == null) {
        state = state.copyWith(isDownloading: false);
        return;
      }
      state = state.copyWith(
        mediaFile: File(mediaPath),
        videoThumbnailFile: null,
        isDownloading: false,
      );
      if (state.mediaFile?.path == mediaPath) {
        final videoThumbnailFile = await getThumbnailData(mediaPath);
        videoThumbnailFile.map((p0) {
          state = state.copyWith(videoThumbnailFile: p0);
        });
      }
    } catch (e, s) {
      _log.severe('Error downloading media:', e, s);
      state = state.copyWith(
        isDownloading: false,
        mediaChatLoadingState: MediaChatLoadingState.error(
          'Some error occurred ${e.toString()}',
        ),
      );
    }
  }

  //FIXME : This is temporarily solution for media thumb management which lead to security issue.
  // Reference https://github.com/acterglobal/a3/issues/1586
  // Reference https://github.com/acterglobal/a3/issues/1250
  static Future<File?> getThumbnailData(String mediaPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final videoName = p.basenameWithoutExtension(mediaPath);
      final destPath = p.join(tempDir.path, '$videoName.jpg');
      final destFile = File(destPath);
      if (await destFile.exists()) return destFile;
      final generated = await FcNativeVideoThumbnail().getVideoThumbnail(
        srcFile: mediaPath,
        destFile: destPath,
        width: 300,
        height: 300,
        format: 'jpeg',
        quality: 90,
      );
      if (generated) return destFile;
    } catch (e, s) {
      // Handle platform errors.
      _log.severe('Failed to extract video thumbnail', e, s);
    }
    return null;
  }
}
