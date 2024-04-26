import 'dart:io';
import 'package:acter/common/widgets/acter_video_player.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class VideoDialog extends StatelessWidget {
  final String title;
  final File videoFile;

  const VideoDialog({
    super.key,
    required this.title,
    required this.videoFile,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      child: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Share.shareXFiles([XFile(videoFile.path)]);
                  },
                  icon: const Icon(Icons.share),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Expanded(child: ActerVideoPlayer(videoFile: videoFile)),
          ],
        ),
      ),
    );
  }
}
