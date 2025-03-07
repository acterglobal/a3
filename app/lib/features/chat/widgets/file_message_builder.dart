import 'package:acter/common/models/types.dart';
import 'package:acter/features/chat/models/media_chat_state/media_chat_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/files/actions/file_share.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

class FileMessageBuilder extends ConsumerWidget {
  final types.FileMessage message;
  final int messageWidth;
  final bool isReplyContent;
  final String roomId;

  const FileMessageBuilder({
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
    return InkWell(
      onTap: () async {
        final mediaFile =
            ref.read(mediaChatStateProvider(messageInfo)).mediaFile;
        if (mediaFile != null) {
          await openFileShareDialog(context: context, file: mediaFile);
        } else {
          final notifier = ref.read(
            mediaChatStateProvider(messageInfo).notifier,
          );
          await notifier.downloadMedia();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            getFileIcon(context),
            const SizedBox(width: 20),
            fileInfoUI(context),
            const SizedBox(width: 10),
            if (mediaState.mediaChatLoadingState.isLoading ||
                mediaState.isDownloading)
              const CircularProgressIndicator()
            else if (mediaState.mediaFile == null)
              const Icon(Icons.download),
          ],
        ),
      ),
    );
  }

  Widget getFileIcon(BuildContext context) {
    final extension = p.extension(message.name);
    IconData iconData = switch (extension) {
      '.png' || '.jpg' || '.jpeg' => Atlas.file_image,
      '.pdf' => Icons.picture_as_pdf,
      '.doc' => Atlas.file,
      '.mp4' => Atlas.file_video,
      '.mp3' => Atlas.music_file,
      '.rtf' || '.txt' => Atlas.lines_file,
      _ => Atlas.lines_file,
    };
    return Icon(iconData, size: 28);
  }

  Widget fileInfoUI(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.name,
            style: textTheme.labelLarge,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Text(
            formatBytes(message.size.truncate()),
            style: textTheme.labelMedium?.copyWith(color: colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
