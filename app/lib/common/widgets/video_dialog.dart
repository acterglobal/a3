import 'dart:io';
import 'package:acter/common/widgets/acter_video_player.dart';
import 'package:acter/features/files/widgets/share_file_button.dart';
import 'package:flutter/material.dart';

class VideoDialog extends StatelessWidget {
  final String title;
  final File videoFile;

  const VideoDialog({super.key, required this.title, required this.videoFile});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [ShareFileButton(file: videoFile)],
        ),
        body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(8.0),
          child: ActerVideoPlayer(videoFile: videoFile),
        ),
      ),
    );
  }
}
