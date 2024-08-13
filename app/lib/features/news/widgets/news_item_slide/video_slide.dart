import 'dart:io';

import 'package:acter/common/widgets/acter_video_player.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final _log = Logger('a3::news::widget::video_slide');

class VideoSlide extends StatelessWidget {
  final NewsSlide slide;
  final Color bgColor;
  final Color fgColor;

  const VideoSlide({
    super.key,
    required this.slide,
    required this.bgColor,
    required this.fgColor,
  });

  Future<File> getNewsVideo() async {
    final newsVideo = await slide.sourceBinary(null);
    final videoName = slide.uniqueId();
    final tempDir = await getTemporaryDirectory();
    final filePath = p.join(tempDir.path, videoName);
    File file = File(filePath);
    if (!(await file.exists())) {
      await file.create();
      file.writeAsBytesSync(newsVideo.asTypedList());
    }
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: NewsUpdateKeys.videoNewsContent,
      color: bgColor,
      alignment: Alignment.center,
      child: FutureBuilder<File>(
        future: getNewsVideo(),
        builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
          if (snapshot.hasError) {
            _log.severe(
              'Failed to load video of slide',
              snapshot.error,
              snapshot.stackTrace,
            );
            return Center(
              child: Text(L10n.of(context).errorLoading(snapshot.error!)),
            );
          }

          if (snapshot.hasData &&
              snapshot.connectionState == ConnectionState.done) {
            return ActerVideoPlayer(
              key: Key('news-slide-video-${snapshot.data!.path}'),
              videoFile: snapshot.data!,
            );
          }

          return Center(child: Text(L10n.of(context).loadingVideo));
        },
      ),
    );
  }
}
