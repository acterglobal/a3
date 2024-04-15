import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

// Attachments Selection Media Type Widget (Mobile)
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
              if (onTapCamera != null) onTapCamera!();
            },
            leading: Icon(Atlas.camera, color: iconColor),
            title: Text(L10n.of(context).camera),
          ),
        ListTile(
          onTap: () {
            if (onTapImage != null) onTapImage!();
          },
          leading: Icon(Atlas.file_image, color: iconColor),
          title: Text(L10n.of(context).image),
        ),
        ListTile(
          onTap: () {
            if (onTapVideo != null) onTapVideo!();
          },
          leading: Icon(Atlas.file_video, color: iconColor),
          title: Text(L10n.of(context).video),
        ),
        ListTile(
          onTap: () {
            if (onTapFile != null) onTapFile!();
          },
          leading: Icon(Atlas.file, color: iconColor),
          title: Text(L10n.of(context).file),
        ),
        ListTile(
          onTap: () => Navigator.of(context).pop(),
          contentPadding: const EdgeInsets.all(0),
          title: Text(L10n.of(context).cancel, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
