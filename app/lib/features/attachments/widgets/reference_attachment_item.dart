import 'package:acter/features/events/widgets/event_item.dart';
import 'package:acter/features/pins/widgets/pin_list_item_widget.dart';
import 'package:acter/features/tasks/widgets/task_list_item_card.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Attachment;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final defaultWidget = SizedBox.shrink();

    final refDetails = attachment.refDetails();
    if (refDetails == null) return defaultWidget;

    final refObjectId = refDetails.targetIdStr();
    final refObjectType = refDetails.typeStr();
    if (refObjectId == null) return defaultWidget;

    switch (refObjectType) {
      case 'pin':
        return PinListItemWidget(
          pinId: refObjectId,
          refDetails: refDetails,
          showPinIndication: true,
          cardMargin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        );
      case 'calendar-event':
        return EventItem(
          eventId: refObjectId,
          refDetails: refDetails,
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        );
      case 'task-list':
        return TaskListItemCard(
          taskListId: refObjectId,
          refDetails: refDetails,
          showOnlyTaskList: true,
          canExpand: false,
          showTaskListIndication: true,
          cardMargin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        );
      default:
        return defaultWidget;
    }
  }
}
