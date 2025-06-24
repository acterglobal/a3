import 'dart:io';

import 'package:acter/common/models/types.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/attachments/actions/add_edit_link_bottom_sheet.dart';
import 'package:acter/features/attachments/models/attachment_model.dart';
import 'package:acter/features/attachments/types.dart';
import 'package:acter/features/attachments/widgets/attachment_preview/media_attachment_preview_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:image_picker/image_picker.dart';

enum AttachmentOptions { link, camera, image, video, audio, file }

// Attachments Selection Media Type Widget (Mobile)
class AttachmentSelectionOptions extends StatelessWidget {
  final OnAttachmentSelected onSelected;
  final OnLinkSelected? onLinkSelected;

  const AttachmentSelectionOptions({
    super.key,
    required this.onSelected,
    this.onLinkSelected,
  });

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    final onSelectLink = onLinkSelected;
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            if (onSelectLink != null)
              _attachmentOptionItem(
                context: context,
                title: lang.link,
                iconData: AttachmentIconType.link.icon,
                iconColor: AttachmentIconType.link.color,
                onTap: () => onTapLink(context, onSelectLink),
              ),
            if (!isDesktop)
              _attachmentOptionItem(
                context: context,
                title: lang.camera,
                iconData: AttachmentIconType.camera.icon,
                iconColor: AttachmentIconType.camera.color,
                onTap: () => onTapCamera(context),
              ),
            _attachmentOptionItem(
              context: context,
              title: lang.image,
              iconData: AttachmentIconType.image.icon,
              iconColor: AttachmentIconType.image.color,
              onTap: () => onTapImage(context),
            ),
            _attachmentOptionItem(
              context: context,
              title: lang.video,
              iconData: AttachmentIconType.video.icon,
              iconColor: AttachmentIconType.video.color,
              onTap: () => onTapVideo(context),
            ),
            _attachmentOptionItem(
              context: context,
              title: lang.audio,
              iconData: AttachmentIconType.audio.icon,
              iconColor: AttachmentIconType.audio.color,
              onTap: () => onTapAudio(context),
            ),
            _attachmentOptionItem(
              context: context,
              title: lang.file,
              iconData: AttachmentIconType.file.icon,
              iconColor: AttachmentIconType.file.color,
              onTap: () => onTapFile(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _attachmentOptionItem({
    required BuildContext context,
    required String title,
    required IconData iconData,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 100,
        width: 100,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(iconData, color: iconColor, size: 26),
            ),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }

  Future<void> onTapLink(
    BuildContext context,
    Future<void> Function(String, String) callback,
  ) async {
    showAddEditLinkBottomSheet(
      context: context,
      bottomSheetTitle: L10n.of(context).addLink,
      onSave: (title, link) {
        Navigator.pop(context);
        callback(title, link);
      },
    );
  }

  Future<void> onTapCamera(BuildContext context) async {
    XFile? imageFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );
    if (imageFile == null) return;
    List<File> files = [File(imageFile.path)];
    if (!context.mounted) return;
    Navigator.pop(context);
    _showMediaAttachmentPreview(
      context,
      files,
      AttachmentType.camera,
      onSelected,
    );
  }

  Future<void> onTapImage(BuildContext context) async {
    XFile? imageFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (imageFile == null) return;
    List<File> files = [File(imageFile.path)];
    if (!context.mounted) return;
    Navigator.pop(context);
    _showMediaAttachmentPreview(
      context,
      files,
      AttachmentType.image,
      onSelected,
    );
  }

  Future<void> onTapVideo(BuildContext context) async {
    XFile? imageFile = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
    );
    if (imageFile == null) return;
    List<File> files = [File(imageFile.path)];
    if (!context.mounted) return;
    Navigator.pop(context);
    _showMediaAttachmentPreview(
      context,
      files,
      AttachmentType.video,
      onSelected,
    );
  }

  Future<void> onTapAudio(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );
    if (result == null) return;
    List<File> files = [];
    for (final path in result.paths) {
      if (path != null) files.add(File(path));
    }
    if (!context.mounted) return;
    Navigator.pop(context);
    _showMediaAttachmentPreview(
      context,
      files,
      AttachmentType.audio,
      onSelected,
    );
  }

  Future<void> onTapFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );
    if (result == null) return;
    List<File> files = [];
    for (final path in result.paths) {
      if (path != null) files.add(File(path));
    }
    if (!context.mounted) return;
    Navigator.pop(context);
    _showMediaAttachmentPreview(
      context,
      files,
      AttachmentType.file,
      onSelected,
    );
  }

  void _showMediaAttachmentPreview(
    BuildContext context,
    List<File> selectedFiles,
    AttachmentType type,
    OnAttachmentSelected handleFileUpload,
  ) {
    showDialog(
      context: context,
      builder: (_) {
        return MediaAttachmentPreviewWidget(
          selectedFiles: selectedFiles,
          handleFileUpload: (files) => handleFileUpload(files, type),
        );
      },
    );
  }
}
