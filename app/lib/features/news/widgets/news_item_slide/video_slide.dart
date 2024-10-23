import 'dart:io';

import 'package:acter/common/widgets/acter_video_player.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

final _log = Logger('a3::news::video_slide');

class VideoSlide extends StatelessWidget {
  final NewsSlide slide;

  const VideoSlide({
    super.key,
    required this.slide,
  });

  Future<File> getNewsVideoFile() async {
    final newsVideo = await slide.sourceBinary(null);
    final videoName = slide.uniqueId();
    final tempDir = await getTemporaryDirectory();
    final filePath = p.join(tempDir.path, videoName);
    File file = File(filePath);
    if (!await file.exists()) {
      await file.create();
      file.writeAsBytesSync(newsVideo.asTypedList());
    }
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: NewsUpdateKeys.videoNewsContent,
      child: renderVideoContent(),
    );
  }

  Widget renderVideoContent() {
    return FutureBuilder<File>(
      future: getNewsVideoFile(),
      builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
        final data = snapshot.data;
        final error = snapshot.error;
        if (data != null && snapshot.connectionState == ConnectionState.done) {
          return buildVideoUI(data);
        } else if (error != null) {
          return buildVideoLoadingErrorUI(context, error, snapshot.stackTrace);
        }
        return buildVideoLoadingUI();
      },
    );
  }

  Widget buildVideoUI(File videoFile) {
    return ActerVideoPlayer(
      key: Key('news-slide-video-${videoFile.path}'),
      videoFile: videoFile,
    );
  }

  Widget buildVideoLoadingUI() {
    return Center(
      child: Icon(
        PhosphorIcons.video(),
        size: 100,
      ),
    );
  }

  Widget buildVideoLoadingErrorUI(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    _log.severe('Failed to load video of slide', error, stackTrace);
    return Center(
      child: Text(L10n.of(context).loadingFailed(error)),
    );
  }
}
