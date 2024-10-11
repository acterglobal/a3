import 'dart:io';

import 'package:acter/common/models/attachment_media_state/attachment_media_state.dart';
import 'package:acter/features/attachments/providers/attachment_providers.dart';
import 'package:acter/features/files/actions/file_share.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Attachment;
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FileView extends ConsumerWidget {
  final Attachment attachment;
  final bool? openView;

  const FileView({
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
      return filePlaceholder(context, attachment, ref);
    } else {
      return fileUI(context, mediaFile);
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

  Widget filePlaceholder(
    BuildContext context,
    Attachment attachment,
    WidgetRef ref,
  ) {
    final msgContent = attachment.msgContent();
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
                  Icons.description,
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  formatBytes(msgContent.size()!.truncate()),
                  style: Theme.of(context).textTheme.labelSmall!,
                  textScaler: const TextScaler.linear(0.7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget fileUI(BuildContext context, File mediaFile) {
    return InkWell(
      onTap: openView != false
          ? () async =>
              await openFileShareDialog(context: context, file: mediaFile)
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: const Icon(
          Icons.description,
          size: 22,
        ),
      ),
    );
  }
}
