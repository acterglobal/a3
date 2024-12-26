import 'package:acter/common/actions/redact_content.dart';
import 'package:acter/features/events/widgets/event_item.dart';
import 'package:acter/features/pins/widgets/pin_list_item_widget.dart';
import 'package:acter/features/tasks/widgets/task_list_item_card.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Attachment;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

// Attachment item UI for References
class ReferenceAttachmentItem extends ConsumerWidget {
  final Attachment attachment;
  final bool canEdit;

  const ReferenceAttachmentItem({
    super.key,
    required this.attachment,
    this.canEdit = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final defaultWidget = SizedBox.shrink();

    final eventId = attachment.attachmentIdStr();
    final roomId = attachment.roomIdStr();
    final refDetails = attachment.refDetails();
    if (refDetails == null) return defaultWidget;

    final refObjectId = refDetails.targetIdStr();
    final refObjectType = refDetails.typeStr();
    if (refObjectId == null) return defaultWidget;

    final objectWidget = switch (refObjectType) {
      'pin' => PinListItemWidget(
          pinId: refObjectId,
          refDetails: refDetails,
          showPinIndication: true,
          cardMargin: EdgeInsets.zero,
        ),
      'calendar-event' => EventItem(
          eventId: refObjectId,
          refDetails: refDetails,
          margin: EdgeInsets.zero,
        ),
      'task-list' => TaskListItemCard(
          taskListId: refObjectId,
          refDetails: refDetails,
          showOnlyTaskList: true,
          canExpand: false,
          showTaskListIndication: true,
          cardMargin: EdgeInsets.zero,
        ),
      _ => defaultWidget,
    };
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).unselectedWidgetColor),
      ),
      child: Row(
        children: [
          Expanded(child: objectWidget),
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
                      title: lang.removeReference,
                      description: lang.removeReferenceConfirmation,
                      isSpace: true,
                    );
                  },
                  child: Text(
                    lang.remove,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
