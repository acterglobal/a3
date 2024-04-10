import 'dart:io';

import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/news/model/news_slide_model.dart';
import 'package:acter/features/news/providers/news_post_editor_providers.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final _log = Logger('a3::news::utils');

class NewsUtils {
  static Future<File?> getThumbnailData(XFile videoFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final videoName = videoFile.name.split('.').first;
      final destPath = p.join(tempDir.path, '$videoName.jpg');
      final destFile = File(destPath);

      if (await destFile.exists()) {
        return destFile;
      }

      final thumbnailGenerated =
          await FcNativeVideoThumbnail().getVideoThumbnail(
        srcFile: videoFile.path,
        destFile: destPath,
        width: 128,
        height: 128,
        keepAspectRatio: true,
        format: 'jpeg',
        quality: 90,
      );

      if (thumbnailGenerated) {
        return destFile;
      }
    } catch (err, s) {
      // Handle platform errors.
      _log.severe('Error', err, s);
    }
    return null;
  }

  //Add text slide
  static void addTextSlide(WidgetRef ref) {
    final clr = getRandomElement(Colors.primaries);
    NewsSlideItem textSlide = NewsSlideItem(
      type: NewsSlideType.text,
      text: '',
      backgroundColor: clr,
    );
    ref.read(newsStateProvider.notifier).addSlide(textSlide);
  }

  //Add image slide
  static Future<void> addImageSlide(WidgetRef ref) async {
    final clr = getRandomElement(Colors.primaries);
    XFile? imageFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (imageFile != null) {
      final slide = NewsSlideItem(
        type: NewsSlideType.image,
        mediaFile: imageFile,
        backgroundColor: clr,
      );
      ref.read(newsStateProvider.notifier).addSlide(slide);
    }
  }

  //Add video slide
  static Future<void> addVideoSlide(WidgetRef ref) async {
    final clr = getRandomElement(Colors.primaries);
    XFile? videoFile = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
    );
    if (videoFile != null) {
      final slide = NewsSlideItem(
        type: NewsSlideType.video,
        mediaFile: videoFile,
        backgroundColor: clr,
      );
      ref.read(newsStateProvider.notifier).addSlide(slide);
    }
  }
}
