import 'dart:io';

import 'package:acter/common/models/types.dart';
import 'package:acter/common/widgets/acter_video_player.dart';
import 'package:acter/features/attachments/types.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pinch_zoom_release_unzoom/pinch_zoom_release_unzoom.dart';

class MediaAttachmentPreviewWidget extends StatelessWidget {
  final List<File> selectedFiles;
  final AttachmentType type;
  final OnAttachmentSelected handleFileUpload;

  const MediaAttachmentPreviewWidget({
    super.key,
    required this.selectedFiles,
    required this.type,
    required this.handleFileUpload,
  });

  @override
  Widget build(BuildContext context) {
    final file = selectedFiles.first;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
      alignment: Alignment.center,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (type == AttachmentType.image)
            _imagePreview(context, file)
          else if (type == AttachmentType.video)
            ActerVideoPlayer(videoFile: file)
          else
            _unSupportedPreview(context, file),
          _buildCloseBtn(context),
          _buildNameAndSendBtn(context, file),
        ],
      ),
    );
  }

  Widget _buildCloseBtn(BuildContext context) {
    return Positioned(
      top: 10,
      right: 10,
      child: IconButton.filled(
        onPressed: () => Navigator.pop(context),
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        icon: const Icon(Icons.close),
      ),
    );
  }

  Widget _unSupportedPreview(BuildContext context, File file) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Atlas.warning, size: 60),
        const SizedBox(height: 30),
        Text(L10n.of(context).unsupportedFile),
      ],
    );
  }

  Widget _imagePreview(BuildContext context, File file) {
    return Center(
      child: PinchZoomReleaseUnzoomWidget(
        child: Image.file(file, fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildNameAndSendBtn(BuildContext context, File file) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Row(
        children: [
          Expanded(
            child: Text(
              p.basename(file.path),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            alignment: Alignment.center,
            iconSize: 20,
            onPressed: () {
              Navigator.pop(context);
              handleFileUpload([file], type);
            },
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
