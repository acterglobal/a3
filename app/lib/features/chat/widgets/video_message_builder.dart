import 'package:acter/common/models/types.dart';
import 'package:acter/common/widgets/acter_video_player.dart';
import 'package:acter/common/widgets/video_dialog.dart';
import 'package:acter/features/chat/models/media_chat_state/media_chat_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VideoMessageBuilder extends ConsumerWidget {
  final types.VideoMessage message;
  final int messageWidth;
  final bool isReplyContent;
  final Convo convo;

  const VideoMessageBuilder({
    super.key,
    required this.convo,
    required this.message,
    required this.messageWidth,
    this.isReplyContent = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = convo.getRoomIdStr();
    final ChatMessageInfo messageInfo = (messageId: message.id, roomId: roomId);
    final mediaState = ref.watch(mediaChatStateProvider(messageInfo));
    if (mediaState.mediaChatLoadingState.isLoading ||
        mediaState.isDownloading) {
      return loadingIndication(context);
    } else if (mediaState.mediaFile == null) {
      return videoPlaceholder(context, roomId, mediaState, ref);
    } else {
      return videoUI(context, mediaState);
    }
  }

  Widget loadingIndication(BuildContext context) {
    return const SizedBox(
      width: 150,
      height: 150,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget videoPlaceholder(
    BuildContext context,
    String roomId,
    MediaChatState mediaState,
    WidgetRef ref,
  ) {
    return InkWell(
      onTap: () async {
        if (mediaState.mediaFile != null) {
          showAdaptiveDialog(
            context: context,
            barrierDismissible: false,
            useRootNavigator: false,
            builder: (ctx) => VideoDialog(
              title: message.name,
              videoFile: mediaState.mediaFile!,
            ),
          );
        } else {
          await ref
              .read(
                mediaChatStateProvider(
                  (messageId: message.id, roomId: roomId),
                ).notifier,
              )
              .downloadMedia();
        }
      },
      child: SizedBox(
        width: 200,
        height: 150,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.download,
              size: 28,
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.video_library_rounded,
                    size: 18,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    formatBytes(message.size.truncate()),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget videoUI(
    BuildContext context,
    MediaChatState mediaState,
  ) {
    return ClipRRect(
      borderRadius:
          isReplyContent ? BorderRadius.circular(6) : BorderRadius.circular(15),
      child: SizedBox(
        height: 150,
        child: ActerVideoPlayer(
          videoFile: mediaState.mediaFile!,
          onTapFullScreen: () {
            showAdaptiveDialog(
              context: context,
              barrierDismissible: false,
              useRootNavigator: false,
              builder: (ctx) => VideoDialog(
                title: message.name,
                videoFile: mediaState.mediaFile!,
              ),
            );
          },
        ),
      ),
    );
  }
}
