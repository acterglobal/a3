import 'dart:io';
import 'dart:math';
import 'package:acter/features/news/model/news_slide_model.dart';
import 'package:acter/features/news/providers/news_post_editor_providers.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class NewsUtils {
  static Future<File?> getThumbnailData(XFile videoFile) async {
    try {
      final tempPath = await getTemporaryDirectory();

      final destFile = File('${tempPath.path}/${videoFile.name}');

      if (await destFile.exists()) {
        return destFile;
      }

      final thumbnailGenerated =
          await FcNativeVideoThumbnail().getVideoThumbnail(
        srcFile: videoFile.path,
        destFile: destFile.path,
        width: 128,
        height: 128,
        keepAspectRatio: true,
        format: 'jpeg',
        quality: 90,
      );

      if (thumbnailGenerated) {
        return destFile;
      }
    } catch (err) {
      // Handle platform errors.
      debugPrint('Error => $err');
    }
    return null;
  }

  //Add text slide
  static void addTextSlide(WidgetRef ref) {
    NewsSlideItem textSlide = NewsSlideItem(
      type: NewsSlideType.text,
      text: '',
      backgroundColor:
          Colors.primaries[Random().nextInt(Colors.primaries.length)],
    );
    ref.watch(newSlideListProvider).addSlide(textSlide);
  }

  //Add image slide
  static Future<void> addImageSlide(WidgetRef ref) async {
    XFile? imageFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (imageFile != null) {
      ref.watch(newSlideListProvider).addSlide(
            NewsSlideItem(
              type: NewsSlideType.image,
              mediaFile: imageFile,
            ),
          );
    }
  }

  //Add video slide
  static Future<void> addVideoSlide(WidgetRef ref) async {
    XFile? videoFile =
        await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (videoFile != null) {
      ref.watch(newSlideListProvider).addSlide(
            NewsSlideItem(
              type: NewsSlideType.video,
              mediaFile: videoFile,
            ),
          );
    }
  }
}
