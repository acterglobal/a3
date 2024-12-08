import 'dart:io';

import 'package:acter/common/models/types.dart';
import 'package:acter/common/toolkit/errors/inline_error_button.dart';
import 'package:acter/common/widgets/image_dialog.dart';
import 'package:acter/features/chat/models/media_chat_state/media_chat_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show MsgContent;
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ImageMessageEvent extends ConsumerWidget {
  final String roomId;
  final String messageId;
  final String? eventId;
  final MsgContent content;

  const ImageMessageEvent({
    super.key,
    required this.messageId,
    required this.roomId,
    required this.content,
    this.eventId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ChatMessageInfo messageInfo =
        (messageId: eventId ?? messageId, roomId: roomId);
    final mediaState = ref.watch(mediaChatStateProvider(messageInfo));
    if (mediaState.mediaChatLoadingState.isLoading ||
        mediaState.isDownloading) {
      return loadingIndication(context);
    }
    final mediaFile = mediaState.mediaFile;
    if (mediaFile == null) {
      return imagePlaceholder(context, roomId, ref);
    } else {
      return imageUI(context, ref, mediaFile);
    }
  }

  Widget loadingIndication(BuildContext context) {
    return const SizedBox(
      width: 150,
      height: 150,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget imagePlaceholder(
    BuildContext context,
    String roomId,
    WidgetRef ref,
  ) {
    final msgSize = content.size();
    if (msgSize == null) return const SizedBox.shrink();
    return InkWell(
      onTap: () async {
        final notifier = ref.read(
          mediaChatStateProvider(
            (messageId: messageId, roomId: roomId),
          ).notifier,
        );
        await notifier.downloadMedia();
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
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.image,
                    size: 18,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    formatBytes(msgSize.truncate()),
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

  Widget imageUI(BuildContext context, WidgetRef ref, File mediaFile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: () {
          showAdaptiveDialog(
            context: context,
            barrierDismissible: false,
            useRootNavigator: false,
            builder: (context) => ImageDialog(
              title: content.body(),
              imageFile: mediaFile,
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 300,
              maxHeight: 300,
            ),
            child: imageFileView(context, ref, mediaFile),
          ),
        ),
      ),
    );
  }

  Widget imageFileView(BuildContext context, WidgetRef ref, File mediaFile) {
    return Image.file(
      mediaFile,
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
      errorBuilder: (context, error, stack) => ActerInlineErrorButton.icon(
        icon: Icon(PhosphorIcons.imageBroken()),
        error: error,
        stack: stack,
        textBuilder: L10n.of(context).couldNotLoadImage,
        onRetryTap: () {
          final ChatMessageInfo messageInfo =
              (messageId: eventId ?? messageId, roomId: roomId);
          ref.invalidate(mediaChatStateProvider(messageInfo));
        },
      ),
      fit: BoxFit.cover,
    );
  }
}
