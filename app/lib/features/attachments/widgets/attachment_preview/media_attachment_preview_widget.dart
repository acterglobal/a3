import 'dart:io';

import 'package:acter/common/widgets/acter_video_player.dart';
import 'package:acter/features/attachments/widgets/attachment_preview/audio_attachment_preview.dart';
import 'package:acter/features/attachments/widgets/attachment_preview/file_attachment_preview.dart';
import 'package:acter/features/attachments/widgets/attachment_preview/media_thumbnail_preview_list.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:pinch_zoom_release_unzoom/pinch_zoom_release_unzoom.dart';

class MediaAttachmentPreviewWidget extends StatefulWidget {
  final List<File> selectedFiles;
  final Function(List<File>) handleFileUpload;

  const MediaAttachmentPreviewWidget({
    super.key,
    required this.selectedFiles,
    required this.handleFileUpload,
  });

  @override
  State<MediaAttachmentPreviewWidget> createState() =>
      _MediaAttachmentPreviewWidgetState();
}

class _MediaAttachmentPreviewWidgetState
    extends State<MediaAttachmentPreviewWidget> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void didUpdateWidget(MediaAttachmentPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset current index if selectedFiles has changed
    if (oldWidget.selectedFiles != widget.selectedFiles) {
      setState(() {
        _currentIndex = 0;
      });
      // Jump to the first page when files change
      _pageController.jumpToPage(0);
    }
  }

  void _onPageChanged(int index) {
    _pageController.jumpToPage(index);
    setState(() => _currentIndex = index);
  }

  void _onDeleted(int index) {
    if (widget.selectedFiles.length == 1) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      if (index == widget.selectedFiles.length - 1) {
        _currentIndex = _currentIndex - 1;
        _onPageChanged(_currentIndex);
      }
      widget.selectedFiles.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
      alignment: Alignment.center,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildPageView(context),
          _buildCloseBtn(context),
          _mediaThumbnailPreviewList(context),
          _buildNameAndSendBtn(context),
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

  Widget _buildPageView(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.selectedFiles.length,
      itemBuilder: (context, index) {
        final file = widget.selectedFiles[index];
        return _buildMediaPreviewItem(context, file);
      },
      onPageChanged: _onPageChanged,
    );
  }

  Widget _buildMediaPreviewItem(BuildContext context, File file) {
    final mimeType = lookupMimeType(file.path);
    if (mimeType?.startsWith('image') ?? false) {
      return _imagePreview(context, file);
    } else if (mimeType?.startsWith('video') ?? false) {
      return ActerVideoPlayer(videoFile: file);
    } else if (mimeType?.startsWith('audio') ?? false) {
      return AudioAttachmentPreview(file: file);
    } else {
      return FileAttachmentPreview(file: file);
    }
  }

  Widget _imagePreview(BuildContext context, File file) {
    return Center(
      child: PinchZoomReleaseUnzoomWidget(
        child: Image.file(file, fit: BoxFit.contain),
      ),
    );
  }

  Widget _mediaThumbnailPreviewList(BuildContext context) {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: MediaThumbnailPreviewList(
        selectedFiles: widget.selectedFiles,
        currentIndex: _currentIndex,
        onPageChanged: _onPageChanged,
        onDeleted: _onDeleted,
      ),
    );
  }

  Widget _buildNameAndSendBtn(BuildContext context) {
    final file = widget.selectedFiles[_currentIndex];
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
              widget.handleFileUpload(widget.selectedFiles);
            },
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
