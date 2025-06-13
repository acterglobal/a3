import 'dart:io';

import 'package:acter/common/models/types.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/features/attachments/widgets/file_attachment_preview.dart';
import 'package:acter/features/news/news_utils/news_utils.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class MultipleMediaPreviewList extends StatelessWidget {
  final List<File> selectedFiles;
  final int currentIndex;
  final AttachmentType type;
  final Function(int index) onPageChanged;
  final Function(int index) onDeleted;

  const MultipleMediaPreviewList({
    super.key,
    required this.selectedFiles,
    required this.type,
    required this.currentIndex,
    required this.onPageChanged,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedFiles.length <= 1) return const SizedBox.shrink();

    return Container(
      height: 40,
      alignment: Alignment.center,
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: selectedFiles.length,
        itemBuilder: (context, index) {
          return _buildMediaPreview(context, index);
        },
      ),
    );
  }

  Widget _buildMediaPreview(BuildContext context, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final file = selectedFiles[index];
    return GestureDetector(
      onTap: () => onPageChanged(index),
      child: Container(
        height: 40,
        width: 40,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                index == currentIndex
                    ? colorScheme.primary
                    : colorScheme.outline,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            switch (type) {
              AttachmentType.image => _imagePreview(context, file),
              AttachmentType.camera => _imagePreview(context, file),
              AttachmentType.video => _videoPreview(context, file),
              AttachmentType.audio => Icon(ActerIcon.fileAudio.data, size: 20),
              AttachmentType.file => FileAttachmentPreview(
                file: file,
                iconSize: 20,
              ),
              _ => Icon(ActerIcon.file.data, size: 20),
            },
            if (index == currentIndex) _buildDeleteIcon(context, index),
          ],
        ),
      ),
    );
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
          ActerIcon.trash.data,
          size: 20,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

  Widget _imagePreview(BuildContext context, File file) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(file, fit: BoxFit.fitWidth),
    );
  }

  Widget _videoPreview(BuildContext context, File file) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: FutureBuilder(
        future: NewsUtils.getThumbnailData(XFile(file.path)),
        builder: (context, snapshot) {
          final thumbnail = snapshot.data;
          return thumbnail != null
              ? Image.file(thumbnail, fit: BoxFit.cover)
              : Icon(ActerIcon.video.data, size: 20);
        },
      ),
    );
  }
}
