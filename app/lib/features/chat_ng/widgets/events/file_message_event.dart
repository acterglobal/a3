import 'package:acter/common/models/types.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/models/media_chat_state/media_chat_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat_ng/widgets/message_timestamp_widget.dart';
import 'package:acter/features/files/actions/file_share.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show MsgContent;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:path/path.dart' as p;

class FileMessageEvent extends ConsumerWidget {
  final String roomId;
  final String messageId;
  final MsgContent content;
  final int? timestamp;

  const FileMessageEvent({
    super.key,
    required this.roomId,
    required this.messageId,
    required this.content,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ChatMessageInfo messageInfo = (messageId: messageId, roomId: roomId);
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

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          getFileIcon(context),
          const SizedBox(width: 20),
          Flexible(child: fileInfoUI(context)),
          const SizedBox(width: 10),
          if (mediaState.mediaChatLoadingState.isLoading ||
              mediaState.isDownloading)
            const CircularProgressIndicator()
          else if (mediaState.mediaFile == null)
            const Icon(Icons.download),
        ],
      ),
    );
  }

  Widget getFileIcon(BuildContext context) {
    final extension = p.extension(content.body());
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
    final msgSize = content.size();
    if (msgSize == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            content.body(),
            style: textTheme.labelLarge,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          formatBytes(msgSize.truncate()),
          style: textTheme.labelMedium,
          overflow: TextOverflow.ellipsis,
        ),

        if (timestamp != null)
          Align(
            alignment: Alignment.bottomRight,
            child: MessageTimestampWidget(
              timestamp: timestamp.expect('should not be null'),
            ),
          ),
      ],
    );
  }
}
