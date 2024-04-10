import 'package:acter/features/news/model/keys.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

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
        ListTile(
          title: Text(L10n.of(context).newUpdate),
        ),
        ListTile(
          key: NewsUpdateKeys.addTextSlide,
          onTap: () {
            Navigator.of(context).pop();
            if (onTapAddText != null) onTapAddText!();
          },
          leading: const Icon(Atlas.size_text),
          title: Text(L10n.of(context).addTextSlide),
        ),
        ListTile(
          key: NewsUpdateKeys.addImageSlide,
          onTap: () {
            Navigator.of(context).pop();
            if (onTapImage != null) onTapImage!();
          },
          leading: const Icon(Atlas.file_image),
          title: Text(L10n.of(context).selectPicture),
        ),
        ListTile(
          key: NewsUpdateKeys.addVideoSlide,
          onTap: () {
            Navigator.of(context).pop();
            if (onTapVideo != null) onTapVideo!();
          },
          leading: const Icon(Atlas.file_video),
          title: Text(L10n.of(context).selectVideo),
        ),
        ListTile(
          key: NewsUpdateKeys.cancelButton,
          onTap: () => Navigator.of(context).pop(),
          contentPadding: const EdgeInsets.all(0),
          title: Text(L10n.of(context).cancel, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
