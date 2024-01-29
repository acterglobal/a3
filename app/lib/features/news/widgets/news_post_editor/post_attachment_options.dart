import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class PostAttachmentOptions extends StatelessWidget {
  final VoidCallback? onTapAddText;
  final VoidCallback? onTapImage;
  final VoidCallback? onTapVideo;

  const PostAttachmentOptions({
    super.key,
    this.onTapAddText,
    this.onTapImage,
    this.onTapVideo,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const ListTile(
          title: Text('New Update'),
        ),
        ListTile(
          onTap: () {
            Navigator.of(context).pop();
            if (onTapAddText != null) onTapAddText!();
          },
          leading: const Icon(Atlas.size_text),
          title: const Text('Add Text Slide'),
        ),
        ListTile(
          onTap: () {
            Navigator.of(context).pop();
            if (onTapImage != null) onTapImage!();
          },
          leading: const Icon(Atlas.file_image),
          title: const Text('Select Picture'),
        ),
        ListTile(
          onTap: () {
            Navigator.of(context).pop();
            if (onTapVideo != null) onTapVideo!();
          },
          leading: const Icon(Atlas.file_video),
          title: const Text('Select Video'),
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
