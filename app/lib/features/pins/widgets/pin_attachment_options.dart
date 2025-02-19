import 'dart:async';

import 'package:acter/common/models/types.dart';
import 'package:acter/features/pins/actions/select_pin_attachments.dart';
import 'package:acter/features/pins/actions/set_pin_description.dart';
import 'package:acter/features/pins/actions/set_pin_links.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PinAttachmentOptions extends ConsumerWidget {
  final bool isBottomSheetOpen;

  const PinAttachmentOptions({
    super.key,
    this.isBottomSheetOpen = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildPinAttachmentOptions(context, ref);
  }

  Widget _buildPinAttachmentOptions(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final pinState = ref.watch(createPinStateProvider);
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.spaceAround,
          children: [
            _pinAttachmentOptionItem(
              context: context,
              title: lang.text,
              iconData: Atlas.text,
              onTap: () {
                showEditPinDescriptionBottomSheet(
                  context: context,
                  isBottomSheetOpen: isBottomSheetOpen,
                  htmlBodyDescription:
                      pinState.pinDescriptionParams?.htmlBodyDescription,
                  plainDescription:
                      pinState.pinDescriptionParams?.plainDescription,
                );
              },
            ),
            _pinAttachmentOptionItem(
              context: context,
              title: lang.link,
              iconData: Atlas.link,
              onTap: () => showAddPinLinkBottomSheet(
                context: context,
                ref: ref,
                isBottomSheetOpen: isBottomSheetOpen,
              ),
            ),
            _pinAttachmentOptionItem(
              context: context,
              title: lang.file,
              iconData: Atlas.file,
              onTap: () => selectAttachmentOnTap(
                ref,
                context,
                AttachmentType.file,
              ),
            ),
            _pinAttachmentOptionItem(
              context: context,
              title: lang.image,
              iconData: Atlas.image_gallery,
              onTap: () => selectAttachmentOnTap(
                ref,
                context,
                AttachmentType.image,
              ),
            ),
            _pinAttachmentOptionItem(
              context: context,
              title: lang.video,
              iconData: Atlas.video_camera,
              onTap: () => selectAttachmentOnTap(
                ref,
                context,
                AttachmentType.video,
              ),
            ),
            _pinAttachmentOptionItem(
              context: context,
              title: lang.audio,
              iconData: Atlas.audio_headphones,
              onTap: () => selectAttachmentOnTap(
                ref,
                context,
                AttachmentType.audio,
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
    AttachmentType attachmentType,
  ) async {
    await selectAttachment(L10n.of(context), ref, attachmentType);
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
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Expanded(
              child: Icon(iconData),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}
