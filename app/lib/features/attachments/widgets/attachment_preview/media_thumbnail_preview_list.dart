import 'dart:io';

import 'package:acter/features/attachments/widgets/attachment_preview/file_attachment_preview.dart';
import 'package:acter/features/news/news_utils/news_utils.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MediaThumbnailPreviewList extends StatelessWidget {
  final List<File> selectedFiles;
  final int currentIndex;
  final Function(int index) onPageChanged;
  final Function(int index) onDeleted;
  final double thumbnailSize;

  const MediaThumbnailPreviewList({
    super.key,
    required this.selectedFiles,
    required this.currentIndex,
    required this.onPageChanged,
    required this.onDeleted,
    this.thumbnailSize = 55,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedFiles.length <= 1) return const SizedBox.shrink();

    return Center(
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        scrollDirection: Axis.horizontal,
        itemCount: selectedFiles.length,
        itemBuilder: (context, index) {
          return _buildMediaThumbnailPreviewItem(context, index);
        },
      ),
    );
  }

  Widget _buildMediaThumbnailPreviewItem(BuildContext context, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = index == currentIndex;
    final borderColor = isSelected ? colorScheme.primary : colorScheme.outline;

    return GestureDetector(
      onTap: () => onPageChanged(index),
      child: Container(
        height: thumbnailSize,
        width: thumbnailSize,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildThumbnailView(context, index),
            if (isSelected) _buildDeleteIcon(context, index),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailView(BuildContext context, int index) {
    final file = selectedFiles[index];
    final mimeType = lookupMimeType(file.path);
    if (mimeType?.startsWith('image') ?? false) {
      return _imagePreview(context, file);
    } else if (mimeType?.startsWith('video') ?? false) {
      return _videoPreview(context, file);
    } else if (mimeType?.startsWith('audio') ?? false) {
      return Icon(Atlas.music_file);
    } else {
      return FileAttachmentPreview(file: file, iconSize: 30);
    }
  }

  Widget _buildDeleteIcon(BuildContext context, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: () => onDeleted(index),
        icon: Icon(
          PhosphorIconsRegular.trash,
          size: 20,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

  Widget _imagePreview(BuildContext context, File file) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(file, fit: BoxFit.cover),
    );
  }

  Widget _videoPreview(BuildContext context, File file) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          FutureBuilder(
            future: NewsUtils.getThumbnailData(XFile(file.path)),
            builder: (context, snapshot) {
              final thumbnail = snapshot.data;
              return thumbnail != null
                  ? Image.file(thumbnail, fit: BoxFit.cover)
                  : Icon(PhosphorIconsRegular.video, size: 20);
            },
          ),
          Icon(PhosphorIconsRegular.playCircle),
        ],
      ),
    );
  }
}
