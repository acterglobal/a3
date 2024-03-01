import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class AttachmentOptions extends StatelessWidget {
  final VoidCallback? onTapCamera;
  final VoidCallback? onTapImage;
  final VoidCallback? onTapVideo;
  final VoidCallback? onTapFile;

  const AttachmentOptions({
    super.key,
    this.onTapCamera,
    this.onTapImage,
    this.onTapVideo,
    this.onTapFile,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor = Theme.of(context).colorScheme.primary;
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        if (!isDesktop)
          ListTile(
            onTap: () {
              Navigator.of(context).pop();
              if (onTapCamera != null) onTapCamera!();
            },
            leading: Icon(Atlas.camera, color: iconColor),
            title: const Text('Camera'),
          ),
        ListTile(
          onTap: () {
            Navigator.of(context).pop();
            if (onTapImage != null) onTapImage!();
          },
          leading: Icon(Atlas.file_image, color: iconColor),
          title: const Text('Image'),
        ),
        ListTile(
          onTap: () {
            Navigator.of(context).pop();
            if (onTapVideo != null) onTapVideo!();
          },
          leading: Icon(Atlas.file_video, color: iconColor),
          title: const Text('Video'),
        ),
        ListTile(
          onTap: () {
            Navigator.of(context).pop();
            if (onTapFile != null) onTapFile!();
          },
          leading: Icon(Atlas.file, color: iconColor),
          title: const Text('File'),
        ),
        ListTile(
          onTap: () => Navigator.of(context).pop(),
          contentPadding: const EdgeInsets.all(0),
          title: const Text('Cancel', textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
