import 'dart:async';

import 'package:acter/common/widgets/edit_html_description_sheet.dart';
import 'package:acter/features/pins/Utils/pins_utils.dart';
import 'package:acter/features/pins/models/create_pin_state/pin_attachment_model.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_link_bottom_sheet.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PinAttachmentOptions extends ConsumerWidget {
  final bool isBottomSheetOpen;

  const PinAttachmentOptions({super.key, this.isBottomSheetOpen = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildPinAttachmentOptions(context, ref);
  }

  Widget _buildPinAttachmentOptions(BuildContext context, WidgetRef ref) {
    final pinState = ref.watch(createPinStateProvider);
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
                  descriptionHtmlValue:
                      pinState.pinDescriptionParams?.htmlBodyDescription,
                  descriptionMarkdownValue:
                      pinState.pinDescriptionParams?.plainDescription,
                  onSave: (htmlBodyDescription, plainDescription) {
                    if (isBottomSheetOpen) Navigator.pop(context);
                    Navigator.pop(context);
                    ref
                        .read(createPinStateProvider.notifier)
                        .setDescriptionValue(
                          htmlBodyDescription: htmlBodyDescription,
                          plainDescription: plainDescription,
                        );
                  },
                );
              },
            ),
            _pinAttachmentOptionItem(
              context: context,
              title: 'Link',
              iconData: Atlas.link,
              onTap: () {
                showPinLinkBottomSheet(
                  context: context,
                  bottomSheetTitle: L10n.of(context).addLink,
                  onSave: (title, link) {
                    if (isBottomSheetOpen) Navigator.pop(context);
                    Navigator.pop(context);
                    ref.read(createPinStateProvider.notifier).addAttachment(
                          PinAttachment(
                            pinAttachmentType: PinAttachmentType.link,
                            title: title,
                            link: link,
                          ),
                        );
                  },
                );
              },
            ),
            _pinAttachmentOptionItem(
              context: context,
              title: 'File',
              iconData: Atlas.file,
              onTap: () => selectAttachmentOnTap(
                ref,
                context,
                PinAttachmentType.file,
              ),
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
              onTap: () => selectAttachmentOnTap(
                ref,
                context,
                PinAttachmentType.image,
              ),
            ),
            _pinAttachmentOptionItem(
              context: context,
              title: 'Video',
              iconData: Atlas.video_camera,
              onTap: () => selectAttachmentOnTap(
                ref,
                context,
                PinAttachmentType.video,
              ),
            ),
            _pinAttachmentOptionItem(
              context: context,
              title: 'Audio',
              iconData: Atlas.audio_headphones,
              onTap: () => selectAttachmentOnTap(
                ref,
                context,
                PinAttachmentType.audio,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> selectAttachmentOnTap(
    WidgetRef ref,
    BuildContext context,
    PinAttachmentType pinAttachmentType,
  ) async {
    await selectAttachment(ref, pinAttachmentType);
    if (isBottomSheetOpen && context.mounted) {
      Navigator.pop(context);
    }
  }

  Widget _pinAttachmentOptionItem({
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
}
