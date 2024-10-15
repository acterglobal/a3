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
    final lang = L10n.of(context);
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        ListTile(
          title: Text(lang.newUpdate),
        ),
        ListTile(
          key: NewsUpdateKeys.addTextSlide,
          onTap: () {
            Navigator.pop(context);
            if (onTapAddText != null) onTapAddText!();
          },
          leading: const Icon(Atlas.size_text),
          title: Text(lang.addTextSlide),
        ),
        ListTile(
          key: NewsUpdateKeys.addImageSlide,
          onTap: () {
            Navigator.pop(context);
            if (onTapImage != null) onTapImage!();
          },
          leading: const Icon(Atlas.file_image),
          title: Text(lang.selectPicture),
        ),
        ListTile(
          key: NewsUpdateKeys.addVideoSlide,
          onTap: () {
            Navigator.pop(context);
            if (onTapVideo != null) onTapVideo!();
          },
          leading: const Icon(Atlas.file_video),
          title: Text(lang.selectVideo),
        ),
        ListTile(
          key: NewsUpdateKeys.cancelButton,
          onTap: () => Navigator.pop(context),
          contentPadding: const EdgeInsets.all(0),
          title: Text(lang.cancel, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
