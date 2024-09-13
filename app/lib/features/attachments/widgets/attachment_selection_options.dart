import 'dart:io';

import 'package:acter/common/models/types.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/attachments/actions/add_edit_link_bottom_sheet.dart';
import 'package:acter/features/attachments/types.dart';
import 'package:acter/features/attachments/widgets/attachment_container.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

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
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            if (onLinkSelected != null)
              _attachmentOptionItem(
                context: context,
                title: L10n.of(context).link,
                iconData: Atlas.link,
                onTap: () => onTapLink(context),
              ),
            if (!isDesktop)
              _attachmentOptionItem(
                context: context,
                title: L10n.of(context).camera,
                iconData: Atlas.camera,
                onTap: () => onTapCamera(context),
              ),
            _attachmentOptionItem(
              context: context,
              title: L10n.of(context).image,
              iconData: Atlas.file_image,
              onTap: () => onTapImage(context),
            ),
            _attachmentOptionItem(
              context: context,
              title: L10n.of(context).video,
              iconData: Atlas.file_video,
              onTap: () => onTapVideo(context),
            ),
            _attachmentOptionItem(
              context: context,
              title: L10n.of(context).audio,
              iconData: Atlas.audio_headphones,
              onTap: () => onTapAudio(context),
            ),
            _attachmentOptionItem(
              context: context,
              title: L10n.of(context).file,
              iconData: Atlas.file,
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        height: 100,
        width: 100,
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          children: [
            Expanded(child: Icon(iconData)),
            Text(title),
          ],
        ),
      ),
    );
  }

  Future<void> onTapLink(BuildContext context) async {
    showAddEditLinkBottomSheet(
      context: context,
      bottomSheetTitle: L10n.of(context).addLink,
      onSave: (title, link) {
        Navigator.pop(context);
        onLinkSelected!(title, link);
      },
    );
  }

  Future<void> onTapCamera(BuildContext context) async {
    XFile? imageFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (imageFile != null) {
      List<File> files = [File(imageFile.path)];

      if (context.mounted) {
        Navigator.pop(context);
        _attachmentConfirmation(
          context,
          files,
          AttachmentType.camera,
          onSelected,
        );
      }
    }
  }

  Future<void> onTapImage(BuildContext context) async {
    XFile? imageFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (imageFile != null) {
      List<File> files = [File(imageFile.path)];

      if (context.mounted) {
        Navigator.pop(context);
        _attachmentConfirmation(
          context,
          files,
          AttachmentType.image,
          onSelected,
        );
      }
    }
  }

  Future<void> onTapVideo(BuildContext context) async {
    XFile? imageFile =
        await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (imageFile != null) {
      List<File> files = [File(imageFile.path)];

      if (context.mounted) {
        Navigator.pop(context);
        _attachmentConfirmation(
          context,
          files,
          AttachmentType.video,
          onSelected,
        );
      }
    }
  }

  Future<void> onTapAudio(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );
    if (result != null) {
      final selectedFiles = result.paths.map((path) => File(path!)).toList();

      if (context.mounted) {
        Navigator.pop(context);
        _attachmentConfirmation(
          context,
          selectedFiles,
          AttachmentType.audio,
          onSelected,
        );
      }
    }
  }

  Future<void> onTapFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );
    if (result != null) {
      final selectedFiles = result.paths.map((path) => File(path!)).toList();

      if (context.mounted) {
        Navigator.pop(context);
        _attachmentConfirmation(
          context,
          selectedFiles,
          AttachmentType.file,
          onSelected,
        );
      }
    }
  }

  void _attachmentConfirmation(
    BuildContext context,
    List<File>? selectedFiles,
    AttachmentType type,
    OnAttachmentSelected handleFileUpload,
  ) {
    final size = MediaQuery.of(context).size;
    if (selectedFiles != null && selectedFiles.isNotEmpty) {
      context.isLargeScreen
          ? showAdaptiveDialog(
              context: context,
              builder: (context) => Dialog(
                insetPadding: const EdgeInsets.all(8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: size.width * 0.5,
                    maxHeight: size.height * 0.5,
                  ),
                  child: _FileWidget(selectedFiles, type, handleFileUpload),
                ),
              ),
            )
          : showModalBottomSheet(
              context: context,
              builder: (context) => Padding(
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

  const _FileWidget(
    this.selectedFiles,
    this.type,
    this.handleFileUpload,
  );

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
            children: selectedFiles
                .map((file) => _filePreview(context, file))
                .toList(),
          ),
          _buildActionBtns(context),
        ],
      ),
    );
  }

  Widget _buildActionBtns(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(L10n.of(context).cancel),
          ),
          ActerPrimaryActionButton(
            onPressed: () async {
              Navigator.pop(context);
              handleFileUpload(selectedFiles, type);
            },
            child: Text(L10n.of(context).send),
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
        child: const Center(
          child: Icon(Atlas.file_sound_thin),
        ),
      );
    } else if (type == AttachmentType.video) {
      return AttachmentContainer(
        name: fileName,
        child: const Center(
          child: Icon(Atlas.file_video_thin),
        ),
      );
    } else {
      return AttachmentContainer(
        name: fileName,
        child: const Center(
          child: Icon(Atlas.plus_file_thin),
        ),
      );
    }
  }
}
