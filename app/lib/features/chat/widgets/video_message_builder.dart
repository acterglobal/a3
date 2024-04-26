import 'package:acter/common/models/types.dart';
import 'package:acter/common/widgets/video_dialog.dart';
import 'package:acter/features/chat/models/media_chat_state/media_chat_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

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
    return InkWell(
      onTap: () {
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
      child: ClipRRect(
        borderRadius: isReplyContent
            ? BorderRadius.circular(6)
            : BorderRadius.circular(15),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 300,
            maxHeight: 300,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              videoThumbFileView(context, mediaState),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(30.0),
                ),
                child: Icon(
                  Icons.play_arrow,
                  size: 50.0,
                  semanticLabel: L10n.of(context).play,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget videoThumbFileView(BuildContext context, MediaChatState mediaState) {
    return Image.file(
      mediaState.videoThumbnailFile!,
      frameBuilder: (
        BuildContext context,
        Widget child,
        int? frame,
        bool wasSynchronouslyLoaded,
      ) {
        if (wasSynchronouslyLoaded) {
          return child;
        }
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(seconds: 1),
          curve: Curves.easeOut,
          child: child,
        );
      },
      errorBuilder: (
        BuildContext context,
        Object url,
        StackTrace? error,
      ) {
        return Text(
          L10n.of(context).couldNotLoadImage(error.toString()),
        );
      },
      fit: BoxFit.cover,
    );
  }
}
