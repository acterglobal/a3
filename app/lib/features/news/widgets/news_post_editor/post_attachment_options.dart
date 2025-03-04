import 'package:acter/common/extensions/options.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';

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
        ListTile(title: Text(lang.newUpdate)),
        ListTile(
          key: UpdateKeys.addTextSlide,
          onTap: () {
            Navigator.pop(context);
            onTapAddText.map((cb) => cb());
          },
          leading: const Icon(Atlas.size_text),
          title: Text(lang.addTextSlide),
        ),
        ListTile(
          key: UpdateKeys.addImageSlide,
          onTap: () {
            Navigator.pop(context);
            onTapImage.map((cb) => cb());
          },
          leading: const Icon(Atlas.file_image),
          title: Text(lang.selectPicture),
        ),
        ListTile(
          key: UpdateKeys.addVideoSlide,
          onTap: () {
            Navigator.pop(context);
            onTapVideo.map((cb) => cb());
          },
          leading: const Icon(Atlas.file_video),
          title: Text(lang.selectVideo),
        ),
        ListTile(
          key: UpdateKeys.cancelButton,
          onTap: () => Navigator.pop(context),
          contentPadding: EdgeInsets.zero,
          title: Text(lang.cancel, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
