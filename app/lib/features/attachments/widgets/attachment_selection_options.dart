import 'dart:io';

import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/models/types.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/attachments/actions/add_edit_link_bottom_sheet.dart';
import 'package:acter/features/attachments/models/attachment_model.dart';
import 'package:acter/features/attachments/types.dart';
import 'package:acter/features/attachments/widgets/attachment_container.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

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
    _attachmentConfirmation(context, files, AttachmentType.camera, onSelected);
  }

  Future<void> onTapImage(BuildContext context) async {
    XFile? imageFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (imageFile == null) return;
    List<File> files = [File(imageFile.path)];
    if (!context.mounted) return;
    Navigator.pop(context);
    _attachmentConfirmation(context, files, AttachmentType.image, onSelected);
  }

  Future<void> onTapVideo(BuildContext context) async {
    XFile? imageFile = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
    );
    if (imageFile == null) return;
    List<File> files = [File(imageFile.path)];
    if (!context.mounted) return;
    Navigator.pop(context);
    _attachmentConfirmation(context, files, AttachmentType.video, onSelected);
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
    _attachmentConfirmation(context, files, AttachmentType.audio, onSelected);
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
    _attachmentConfirmation(context, files, AttachmentType.file, onSelected);
  }

  void _attachmentConfirmation(
    BuildContext context,
    List<File> selectedFiles,
    AttachmentType type,
    OnAttachmentSelected handleFileUpload,
  ) {
    if (selectedFiles.isEmpty) return;
    if (context.isLargeScreen) {
      final size = MediaQuery.of(context).size;
      showAdaptiveDialog(
        context: context,
        builder:
            (context) => Dialog(
              insetPadding: const EdgeInsets.all(8),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: size.width * 0.5,
                  maxHeight: size.height * 0.5,
                ),
                child: _FileWidget(selectedFiles, type, handleFileUpload),
              ),
            ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        builder:
            (context) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: _FileWidget(selectedFiles, type, handleFileUpload),
            ),
      );
    }
  }
}

class _FileWidget extends StatelessWidget {
  final List<File> selectedFiles;
  final AttachmentType type;
  final OnAttachmentSelected handleFileUpload;

  const _FileWidget(this.selectedFiles, this.type, this.handleFileUpload);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('${L10n.of(context).attachments} (${selectedFiles.length})'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 5.0,
            runSpacing: 10.0,
            children:
                selectedFiles
                    .map((file) => _filePreview(context, file))
                    .toList(),
          ),
          _buildActionBtns(context),
        ],
      ),
    );
  }

  Widget _buildActionBtns(BuildContext context) {
    final lang = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(lang.cancel),
          ),
          ActerPrimaryActionButton(
            onPressed: () async {
              Navigator.pop(context);
              handleFileUpload(selectedFiles, type);
            },
            child: Text(lang.send),
          ),
        ],
      ),
    );
  }

  Widget _filePreview(BuildContext context, File file) {
    final fileName = p.basename(file.path);
    if (type == AttachmentType.camera || type == AttachmentType.image) {
      return AttachmentContainer(
        name: fileName,
        child: Image.file(file, height: 200, fit: BoxFit.cover),
      );
    } else if (type == AttachmentType.audio) {
      return AttachmentContainer(
        name: fileName,
        child: const Center(child: Icon(Atlas.file_sound_thin)),
      );
    } else if (type == AttachmentType.video) {
      return AttachmentContainer(
        name: fileName,
        child: const Center(child: Icon(Atlas.file_video_thin)),
      );
    } else {
      return AttachmentContainer(
        name: fileName,
        child: const Center(child: Icon(Atlas.plus_file_thin)),
      );
    }
  }
}
