import 'dart:io';

import 'package:acter/common/widgets/acter_video_player.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class VideoSlide extends StatefulWidget {
  final NewsSlide slide;

  const VideoSlide({
    super.key,
    required this.slide,
  });

  @override
  State<VideoSlide> createState() => _VideoSlideState();
}

class _VideoSlideState extends State<VideoSlide> {
  late Future<FfiBufferUint8> newsVideo;
  late MsgContent? msgContent;

  @override
  void initState() {
    super.initState();
    getNewsVideo();
  }

  Future<void> getNewsVideo() async {
    newsVideo = widget.slide.sourceBinary(null);
    msgContent = widget.slide.msgContent();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: newsVideo.then((value) => value.asTypedList()),
      builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
        if (snapshot.hasData) {
          return ActerVideoPlayer(
            videoFile: File.fromRawPath(snapshot.data!),
          );
        } else {
          return const Center(child: Text('Loading video'));
        }
      },
    );
  }
}
