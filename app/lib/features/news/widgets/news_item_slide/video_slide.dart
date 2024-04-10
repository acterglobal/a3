import 'dart:io';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:acter/common/widgets/acter_video_player.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class VideoSlide extends StatefulWidget {
  final NewsSlide slide;
  final Color bgColor;
  final Color fgColor;

  const VideoSlide({
    super.key,
    required this.slide,
    required this.bgColor,
    required this.fgColor,
  });

  @override
  State<VideoSlide> createState() => _VideoSlideState();
}

class _VideoSlideState extends State<VideoSlide> {
  Future<File> getNewsVideo() async {
    final newsVideo = await widget.slide.sourceBinary(null);
    final videoName = widget.slide.uniqueId();
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
      color: widget.bgColor,
      alignment: Alignment.center,
      child: FutureBuilder<File>(
        future: getNewsVideo(),
        builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
          if (snapshot.hasData) {
            return ActerVideoPlayer(
              key: Key(snapshot.data!.path),
              videoFile: snapshot.data!,
            );
          } else {
            return Center(child: Text(L10n.of(context).loadingVideo));
          }
        },
      ),
    );
  }
}
