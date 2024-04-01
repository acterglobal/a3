import 'package:acter/common/models/attachment_media_state/attachment_media_state.dart';
import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/attachment_providers.dart';
import 'package:acter/common/widgets/attachments/attachment_container.dart';
import 'package:acter/common/widgets/image_dialog.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Attachment;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Attachment item UI
class AttachmentItem extends ConsumerWidget {
  final Attachment attachment;
  const AttachmentItem({
    super.key,
    required this.attachment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var msgContent = attachment.msgContent();
    String type = attachment.typeStr();
    if (type == 'image') {
      return AttachmentContainer(
        name: msgContent.body(),
        child: _ImageView(attachment: attachment),
      );
    } else if (type == 'video') {
      return AttachmentContainer(
        name: msgContent.body(),
        child: const Center(
          child: Icon(Atlas.file_video_thin),
        ),
      );
    } else if (type == 'audio') {
      return AttachmentContainer(
        name: msgContent.body(),
        child: const Center(
          child: Icon(Atlas.file_audio_thin),
        ),
      );
    } else {
      return AttachmentContainer(
        name: msgContent.body(),
        child: const Center(child: Icon(Atlas.file_thin)),
      );
    }
  }
}

class _ImageView extends ConsumerWidget {
  final Attachment attachment;
  const _ImageView({required this.attachment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachmentId = attachment.attachmentIdStr();
    final spaceId = attachment.roomIdStr();
    final AttachmentMediaInfo mediaInfo =
        (attachmentId: attachmentId, spaceId: spaceId);
    final mediaState = ref.watch(attachmentMediaStateProvider(mediaInfo));
    if (mediaState.mediaLoadingState.isLoading || mediaState.isDownloading) {
      return loadingIndication(context);
    } else if (mediaState.mediaFile == null) {
      return imagePlaceholder(context, mediaInfo, mediaState, ref);
    } else {
      return imageUI(context, mediaState);
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
    AttachmentMediaInfo mediaInfo,
    AttachmentMediaState mediaState,
    WidgetRef ref,
  ) {
    final msgContent = attachment.msgContent();
    return InkWell(
      onTap: () async {
        if (mediaState.mediaFile != null) {
          showAdaptiveDialog(
            context: context,
            barrierDismissible: false,
            useRootNavigator: false,
            builder: (ctx) => ImageDialog(
              title: msgContent.body(),
              imageFile: mediaState.mediaFile!,
            ),
          );
        } else {
          ref
              .read(attachmentMediaStateProvider(mediaInfo).notifier)
              .downloadMedia();
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.download,
            size: 24,
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.image,
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  formatBytes(msgContent.size()!.truncate()),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget imageUI(BuildContext context, AttachmentMediaState mediaState) {
    return InkWell(
      onTap: () {
        final msgContent = attachment.msgContent();
        showAdaptiveDialog(
          context: context,
          barrierDismissible: false,
          useRootNavigator: false,
          builder: (ctx) => ImageDialog(
            title: msgContent.body(),
            imageFile: mediaState.mediaFile!,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
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
            Object url,
            StackTrace? error,
          ) {
            return Text('Could not load image due to $error');
          },
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
