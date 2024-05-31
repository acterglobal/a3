import 'dart:io';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/acter_video_player.dart';
import 'package:acter/common/widgets/download_button.dart';
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
    final canShare = !isDesktop;
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
                if (canShare)
                  IconButton(
                    onPressed: () {
                      Share.shareXFiles([XFile(videoFile.path)]);
                    },
                    icon: const Icon(Icons.share),
                  ),
                DownloadButton(file: videoFile),
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
