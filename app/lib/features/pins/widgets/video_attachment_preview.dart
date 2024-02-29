import 'dart:io';

import 'package:acter/common/widgets/acter_video_player.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Attachment;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class VideoAttachmentPreview extends StatefulWidget {
  final Attachment attachment;
  const VideoAttachmentPreview({super.key, required this.attachment});

  @override
  State<VideoAttachmentPreview> createState() => _VideoAttachmentState();
}

class _VideoAttachmentState extends State<VideoAttachmentPreview> {
  Future<File> getNewsVideo() async {
    final newsVideo = await widget.attachment.sourceBinary(null);
    final videoName = widget.attachment.msgContent().body();
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
    return Align(
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
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
