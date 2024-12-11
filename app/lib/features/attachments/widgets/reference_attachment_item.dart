import 'package:acter/common/actions/redact_content.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Attachment, RefDetails;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// Attachment item UI for References
class ReferenceAttachmentItem extends ConsumerWidget {
  final Attachment attachment;
  final RefDetails refDetails;
  final bool canEdit;

  // whether item can be viewed on gesture
  final bool? openView;

  const ReferenceAttachmentItem({
    super.key,
    required this.attachment,
    required this.refDetails,
    this.canEdit = false,
    this.openView,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final containerColor = Theme.of(context).colorScheme.surface;
    final eventId = attachment.attachmentIdStr();
    final roomId = attachment.roomIdStr();

    return Container(
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).unselectedWidgetColor),
      ),
      child: ListTile(
        leading: PhosphorIcon(PhosphorIconsThin.tagChevron),
        title: title(context),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canEdit)
              PopupMenuButton<String>(
                key: const Key('attachment-item-menu-options'),
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    key: const Key('attachment-delete'),
                    onTap: () {
                      openRedactContentDialog(
                        context,
                        eventId: eventId,
                        roomId: roomId,
                        title: lang.deleteAttachment,
                        description:
                            lang.areYouSureYouWantToRemoveAttachmentFromPin,
                        isSpace: true,
                      );
                    },
                    child: Text(
                      lang.delete,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget title(BuildContext context) {
    final title = refDetails.title();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title ?? refDetails.toString(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Row(
          children: [
            Text(
              refDetails.typeStr(),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ],
    );
  }
}
