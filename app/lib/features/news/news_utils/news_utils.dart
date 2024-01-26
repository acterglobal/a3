import 'dart:io';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:flutter/cupertino.dart';
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
}
