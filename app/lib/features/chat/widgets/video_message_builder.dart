import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/widgets/acter_video_player.dart';
import 'package:acter/common/widgets/video_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

class VideoMessageBuilder extends ConsumerWidget {
  final types.VideoMessage message;
  final int messageWidth;
  final bool isReplyContent;
  final Convo convo;

  const VideoMessageBuilder({
    Key? key,
    required this.convo,
    required this.message,
    required this.messageWidth,
    this.isReplyContent = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoFile = ref.watch(videoFileFromMessageIdProvider(message.id));
    return videoFile.when(
      data: (videoFileData) {
        return ClipRRect(
          borderRadius: isReplyContent
              ? BorderRadius.circular(6)
              : BorderRadius.circular(15),
          child: SizedBox(
            height: 150,
            child: ActerVideoPlayer(
              videoFile: videoFileData,
              onTapFullScreen: () {
                showAdaptiveDialog(
                  context: context,
                  barrierDismissible: false,
                  useRootNavigator: false,
                  builder: (ctx) => VideoDialog(
                    title: message.name,
                    videoFile: videoFileData,
                  ),
                );
              },
            ),
          ),
        );
      },
      error: (error, stack) => Center(child: Text('Loading failed: $error')),
      loading: () => const Center(child: Text('Loading video..')),
    );
  }
}
