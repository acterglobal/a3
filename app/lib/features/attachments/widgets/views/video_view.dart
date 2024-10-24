import 'dart:io';

import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/models/attachment_media_state/attachment_media_state.dart';
import 'package:acter/common/widgets/acter_video_player.dart';
import 'package:acter/common/widgets/video_dialog.dart';
import 'package:acter/features/attachments/providers/attachment_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Attachment;
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Video attachment preview
class VideoView extends ConsumerWidget {
  final Attachment attachment;
  final bool? openView;

  const VideoView({
    super.key,
    required this.attachment,
    this.openView,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(attachmentMediaStateProvider(attachment));
    if (mediaState.mediaLoadingState.isLoading || mediaState.isDownloading) {
      return loadingIndication(context);
    }
    final mediaFile = mediaState.mediaFile;
    if (mediaFile == null) {
      return videoPlaceholder(context, attachment, ref);
    } else {
      return videoUI(context, mediaFile);
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

  Widget videoPlaceholder(
    BuildContext context,
    Attachment attachment,
    WidgetRef ref,
  ) {
    final msgContent = attachment.msgContent();
    final size =
        msgContent.size().expect('size of video attachment not available');
    return InkWell(
      onTap: () async {
        final notifier =
            ref.read(attachmentMediaStateProvider(attachment).notifier);
        await notifier.downloadMedia();
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
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.video_file,
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  formatBytes(size.truncate()),
                  style: Theme.of(context).textTheme.labelSmall,
                  textScaler: const TextScaler.linear(0.7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget videoUI(BuildContext context, File mediaFile) {
    final msgContent = attachment.msgContent();
    return InkWell(
      onTap: openView != false
          ? () => showAdaptiveDialog(
                context: context,
                barrierDismissible: false,
                useRootNavigator: false,
                builder: (context) => VideoDialog(
                  title: msgContent.body(),
                  videoFile: mediaFile,
                ),
              )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: ActerVideoPlayer(
          hasPlayerControls: false,
          videoFile: mediaFile,
        ),
      ),
    );
  }
}
