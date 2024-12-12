import 'package:acter/common/actions/redact_content.dart';
import 'package:acter/common/widgets/acter_icon_picker/acter_icon_widget.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/color_data.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
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
        leading: refAttachmentIcons(ref),
        title: refAttachmentTitle(ref),
        subtitle: refAttachmentSubTitle(),
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

  Widget refAttachmentTitle(WidgetRef ref) {
    final defaultTitle = Text(refDetails.toString());
    final refObjectType = refDetails.typeStr();
    final refObjectId = refDetails.targetIdStr();

    if (refObjectId == null) return defaultTitle;
    switch (refObjectType) {
      case 'pin':
        final pin = ref.watch(pinProvider(refObjectId)).valueOrNull;
        return pin == null ? defaultTitle : Text(pin.title().toString());
      case 'calendar-event':
        final event = ref.watch(calendarEventProvider(refObjectId)).valueOrNull;
        return event == null ? defaultTitle : Text(event.title().toString());
      case 'task-list':
        final taskList = ref.watch(taskListProvider(refObjectId)).valueOrNull;
        return taskList == null
            ? defaultTitle
            : Text(taskList.name().toString());
      default:
        return defaultTitle;
    }
  }

  Widget refAttachmentSubTitle() {
    return Text(refDetails.typeStr().toString());
  }

  Widget refAttachmentIcons(WidgetRef ref) {
    final defaultIcon = PhosphorIcon(PhosphorIconsThin.tagChevron, size: 30);
    final refObjectType = refDetails.typeStr();
    final refObjectId = refDetails.targetIdStr();

    if (refObjectId == null) return defaultIcon;
    switch (refObjectType) {
      case 'pin':
        final pin = ref.watch(pinProvider(refObjectId)).valueOrNull;
        return ActerIconWidget(
          iconSize: 30,
          color: convertColor(
            pin?.display()?.color(),
            iconPickerColors[0],
          ),
          icon: ActerIcon.iconForPin(
            pin?.display()?.iconStr(),
          ),
        );
      case 'calendar-event':
        return PhosphorIcon(PhosphorIconsThin.calendar, size: 30);
      case 'task-list':
        final taskList = ref.watch(taskListProvider(refObjectId)).valueOrNull;
        return ActerIconWidget(
          iconSize: 30,
          color: convertColor(
            taskList?.display()?.color(),
            iconPickerColors[0],
          ),
          icon: ActerIcon.iconForPin(
            taskList?.display()?.iconStr(),
          ),
        );
      default:
        return defaultIcon;
    }
  }
}
