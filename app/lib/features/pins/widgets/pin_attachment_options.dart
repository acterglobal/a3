import 'package:acter/common/widgets/edit_html_description_sheet.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class PinAttachmentOptions extends StatelessWidget {
  const PinAttachmentOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildPinAttachmentOptions(context);
  }

  Widget _buildPinAttachmentOptions(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _pinAttachmentOptionItem(
              context: context,
              title: 'Text',
              iconData: Atlas.text,
              onTap: () {
                showEditHtmlDescriptionBottomSheet(
                  bottomSheetTitle: L10n.of(context).add,
                  context: context,
                  onSave: (htmlBodyDescription, plainDescription) async {},
                );
              },
            ),
            _pinAttachmentOptionItem(
              context: context,
              title: 'Link',
              iconData: Atlas.link,
              onTap: () {},
            ),
            _pinAttachmentOptionItem(
              context: context,
              title: 'File',
              iconData: Atlas.file,
              onTap: () {},
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _pinAttachmentOptionItem(
              context: context,
              title: 'Image',
              iconData: Atlas.image_gallery,
              onTap: () {},
            ),
            _pinAttachmentOptionItem(
              context: context,
              title: 'Video',
              iconData: Atlas.video_camera,
              onTap: () {},
            ),
            _pinAttachmentOptionItem(
              context: context,
              title: 'Audio',
              iconData: Atlas.audio_headphones,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _pinAttachmentOptionItem({
    required BuildContext context,
    required String title,
    required IconData iconData,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        onTap();
      },
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
}
