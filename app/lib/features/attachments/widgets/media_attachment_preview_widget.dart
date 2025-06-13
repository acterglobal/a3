import 'dart:io';

import 'package:acter/common/models/types.dart';
import 'package:acter/common/widgets/acter_video_player.dart';
import 'package:acter/features/attachments/types.dart';
import 'package:acter/features/attachments/widgets/audio_attachment_preview.dart';
import 'package:acter/features/attachments/widgets/file_attachment_preview.dart';
import 'package:acter/features/attachments/widgets/multiple_media_preview_list.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pinch_zoom_release_unzoom/pinch_zoom_release_unzoom.dart';

class MediaAttachmentPreviewWidget extends StatefulWidget {
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
      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
      alignment: Alignment.center,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildPageView(context),
          _buildCloseBtn(context),
          _multipleMediaPreviewList(context),
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
        return _buildMediaPreview(context, file);
      },
      onPageChanged: _onPageChanged,
    );
  }

  Widget _buildMediaPreview(BuildContext context, File file) {
    return switch (widget.type) {
      AttachmentType.image => _imagePreview(context, file),
      AttachmentType.camera => _imagePreview(context, file),
      AttachmentType.video => ActerVideoPlayer(videoFile: file),
      AttachmentType.audio => AudioAttachmentPreview(file: file),
      AttachmentType.file => FileAttachmentPreview(file: file),
      _ => _unSupportedPreview(context, file),
    };
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

  Widget _multipleMediaPreviewList(BuildContext context) {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: MultipleMediaPreviewList(
        selectedFiles: widget.selectedFiles,
        type: widget.type,
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
              widget.handleFileUpload(widget.selectedFiles, widget.type);
            },
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
