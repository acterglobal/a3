import 'dart:io';

import 'package:acter/common/models/types.dart';
import 'package:acter/common/widgets/video_dialog.dart';
import 'package:acter/features/chat/models/media_chat_state/media_chat_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VideoMessageBuilder extends ConsumerWidget {
  final types.VideoMessage message;
  final int messageWidth;
  final bool isReplyContent;
  final String roomId;

  const VideoMessageBuilder({
    super.key,
    required this.roomId,
    required this.message,
    required this.messageWidth,
    this.isReplyContent = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ChatMessageInfo messageInfo = (
      messageId: message.remoteId ?? message.id,
      roomId: roomId,
    );
    final mediaState = ref.watch(mediaChatStateProvider(messageInfo));
    if (mediaState.mediaChatLoadingState.isLoading ||
        mediaState.isDownloading) {
      return loadingIndication(context);
    }
    final mediaFile = mediaState.mediaFile;
    if (mediaFile == null) {
      return videoPlaceholder(context, roomId, ref);
    } else {
      return videoUI(context, mediaFile, mediaState.videoThumbnailFile);
    }
  }

  Widget loadingIndication(BuildContext context) {
    return const SizedBox(
      width: 150,
      height: 150,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget videoPlaceholder(BuildContext context, String roomId, WidgetRef ref) {
    return InkWell(
      onTap: () async {
        final notifier = ref.read(
          mediaChatStateProvider((
            messageId: message.remoteId ?? message.id,
            roomId: roomId,
          ),).notifier,
        );
        await notifier.downloadMedia();
      },
      child: SizedBox(
        width: 200,
        height: 150,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.download, size: 28),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.video_library_rounded, size: 18),
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

  Widget videoUI(BuildContext context, File mediaFile, File? thumbFile) {
    return InkWell(
      onTap: () {
        showAdaptiveDialog(
          context: context,
          barrierDismissible: false,
          useRootNavigator: false,
          builder:
              (context) =>
                  VideoDialog(title: message.name, videoFile: mediaFile),
        );
      },
      child: ClipRRect(
        borderRadius:
            isReplyContent
                ? BorderRadius.circular(6)
                : BorderRadius.circular(15),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (thumbFile != null) videoThumbFileView(context, thumbFile),
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

  Widget videoThumbFileView(BuildContext context, File thumbFile) {
    return Image.file(
      thumbFile,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
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
      errorBuilder: (context, url, error) {
        return Text(L10n.of(context).couldNotLoadImage(error.toString()));
      },
      fit: BoxFit.cover,
    );
  }
}
