import 'package:acter/common/models/types.dart';
import 'package:acter/common/toolkit/errors/inline_error_button.dart';
import 'package:acter/common/widgets/image_dialog.dart';
import 'package:acter/features/chat/models/media_chat_state/media_chat_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ImageMessageBuilder extends ConsumerWidget {
  final types.ImageMessage message;
  final int messageWidth;
  final bool isReplyContent;
  final String roomId;

  const ImageMessageBuilder({
    super.key,
    required this.roomId,
    required this.message,
    required this.messageWidth,
    this.isReplyContent = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ChatMessageInfo messageInfo = (messageId: message.id, roomId: roomId);
    final mediaState = ref.watch(mediaChatStateProvider(messageInfo));
    if (mediaState.mediaChatLoadingState.isLoading ||
        mediaState.isDownloading) {
      return loadingIndication(context);
    } else if (mediaState.mediaFile == null) {
      return imagePlaceholder(context, roomId, mediaState, ref);
    } else {
      return imageUI(context, ref, mediaState);
    }
  }

  Widget loadingIndication(BuildContext context) {
    return const SizedBox(
      width: 150,
      height: 150,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget imagePlaceholder(
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
            builder: (context) => ImageDialog(
              title: message.name,
              imageFile: mediaState.mediaFile!,
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
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.image,
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

  Widget imageUI(
    BuildContext context,
    WidgetRef ref,
    MediaChatState mediaState,
  ) {
    final size = MediaQuery.of(context).size;
    return InkWell(
      onTap: () {
        showAdaptiveDialog(
          context: context,
          barrierDismissible: false,
          useRootNavigator: false,
          builder: (context) => ImageDialog(
            title: message.name,
            imageFile: mediaState.mediaFile!,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: isReplyContent
            ? BorderRadius.circular(6)
            : BorderRadius.circular(15),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isReplyContent ? size.height * 0.2 : 300,
            maxHeight: isReplyContent ? size.width * 0.2 : 300,
          ),
          child: imageFileView(context, ref, mediaState),
        ),
      ),
    );
  }

  Widget imageFileView(
    BuildContext context,
    WidgetRef ref,
    MediaChatState mediaState,
  ) {
    return Image.file(
      mediaState.mediaFile!,
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
        Object error,
        StackTrace? stack,
      ) =>
          ActerInlineErrorButton.icon(
        icon: Icon(PhosphorIcons.imageBroken()),
        error: error,
        stack: stack,
        textBuilder: L10n.of(context).couldNotLoadImage,
        onRetryTap: () {
          final ChatMessageInfo messageInfo =
              (messageId: message.id, roomId: roomId);
          ref.invalidate(mediaChatStateProvider(messageInfo));
        },
      ),
      fit: BoxFit.cover,
    );
  }
}
