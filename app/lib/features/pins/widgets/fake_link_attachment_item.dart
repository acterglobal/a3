import 'package:acter/common/actions/open_link.dart';
import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/attachments/actions/add_edit_link_bottom_sheet.dart';
import 'package:acter/features/attachments/actions/handle_selected_attachments.dart';
import 'package:acter/features/attachments/providers/attachment_providers.dart';
import 'package:acter/features/attachments/types.dart';
import 'package:acter/features/pins/actions/pin_update_actions.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::pins::fake_link_attachment_item');

class FakeLinkAttachmentItem extends ConsumerWidget {
  final String pinId;

  const FakeLinkAttachmentItem({
    super.key,
    required this.pinId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final pinData = ref.watch(pinProvider(pinId));
    return pinData.when(
      data: (pin) => fakeLinkAttachmentItemUI(context, ref, pin),
      loading: () => Skeletonizer(
        child: Text(lang.loadingPin),
      ),
      error: (e, s) {
        _log.severe('Error loading pin', e, s);
        return Text(
          lang.errorLoadingPin(e),
        );
      },
    );
  }

  Widget fakeLinkAttachmentItemUI(
    BuildContext context,
    WidgetRef ref,
    ActerPin pin,
  ) {
    String link = pin.url() ?? '';
    if (link.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).unselectedWidgetColor),
      ),
      child: ListTile(
        leading: const Icon(Atlas.link),
        onTap: () => openLink(link, context),
        title: Text(
          link,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        trailing: optionMenu(ref, pin, link),
      ),
    );
  }

  Widget? optionMenu(WidgetRef ref, ActerPin pin, String link) {
    //Get my membership details
    final membership =
        ref.read(roomMembershipProvider(pin.roomIdStr())).valueOrNull;
    if (membership?.canString('CanPostPin') != true) return null;

    return PopupMenuButton<String>(
      key: const Key('fake-pink-link-menu-options'),
      icon: const Icon(Icons.more_vert),
      itemBuilder: (context) {
        final lang = L10n.of(context);
        return [
          //Check for can post pin permission
          PopupMenuItem<String>(
            key: const Key('fake-pink-link-edit'),
            onTap: () {
              showAddEditLinkBottomSheet(
                context: context,
                pinLink: link,
                onSave: (title, newLink) async {
                  if (link == newLink) Navigator.pop(context);
                  await handleLinkBackwardSupportOnEdit(
                    context,
                    ref,
                    pin,
                    title,
                    newLink,
                  );
                },
              );
            },
            child: Text(lang.edit),
          ),
          PopupMenuItem<String>(
            key: const Key('fake-pink-link-delete'),
            onTap: () => updatePinLink(context, pin, ''),
            child: Text(
              lang.delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ];
      },
    );
  }

  Future<void> handleLinkBackwardSupportOnEdit(
    BuildContext context,
    WidgetRef ref,
    ActerPin pin,
    String title,
    String link,
  ) async {
    final manager = await ref.read(
      attachmentsManagerProvider(pin.asAttachmentsManagerProvider()).future,
    );
    if (!context.mounted) return;
    //Make link empty on Pin Data
    await updatePinLink(context, pin, '');
    if (!context.mounted) return;
    //Add pin link to attachments
    await handleAttachmentSelected(
      context: context,
      ref: ref,
      manager: manager,
      title: title,
      link: link,
      attachmentType: AttachmentType.link,
      attachments: [],
    );
    if (!context.mounted) return;
    Navigator.pop(context);
  }
}
