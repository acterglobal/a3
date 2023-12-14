import 'package:acter/common/providers/chat_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:share_plus/share_plus.dart';

class FileMessageBuilder extends ConsumerWidget {
  final types.FileMessage message;
  final int messageWidth;
  final bool isReplyContent;
  final Convo convo;

  const FileMessageBuilder({
    Key? key,
    required this.convo,
    required this.message,
    required this.messageWidth,
    this.isReplyContent = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaFile = ref.watch(mediaDownloadProvider(message.id));
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          getFileIcon(context),
          const SizedBox(width: 20),
          fileInfoUI(context),
          const SizedBox(width: 10),
          mediaFile.when(
            data: (mediaFileData) {
              return IconButton(
                onPressed: () {
                  Share.shareXFiles([XFile(mediaFileData.path)]);
                },
                icon: const Icon(Icons.share),
              );
            },
            error: (error, stack) =>
                Center(child: Text('Loading failed: $error')),
            loading: () => const CircularProgressIndicator(),
          ),
        ],
      ),
    );
  }

  Widget getFileIcon(BuildContext context) {
    final extension = message.name.split('.').last;
    IconData iconData;
    switch (extension) {
      case 'png':
      case 'jpg':
      case 'jpeg':
        iconData = Atlas.file_image;
        break;
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        break;
      case 'doc':
        iconData = Atlas.file;
        break;
      case 'mp4':
        iconData = Atlas.file_video;
        break;
      case 'mp3':
        iconData = Atlas.music_file;
        break;
      case 'rtf':
      case 'txt':
      default:
        iconData = Atlas.lines_file;
        break;
    }
    return Icon(iconData, size: 28);
  }

  Widget fileInfoUI(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.name,
            style: Theme.of(context).textTheme.labelLarge,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Text(
            formatBytes(message.size.truncate()),
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}
