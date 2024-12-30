import 'package:acter/common/widgets/event/event_selector_drawer.dart';
import 'package:acter/common/widgets/pin/pin_selector_drawer.dart';
import 'package:acter/common/widgets/share/widgets/attach_options.dart';
import 'package:acter/common/widgets/task/taskList_selector_drawer.dart';
import 'package:acter/features/attachments/actions/handle_selected_attachments.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> addSpaceObjectRefDialog({
  required BuildContext context,
  required AttachmentsManager attachmentManager,
}) async {
  await showModalBottomSheet(
    showDragHandle: true,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    builder: (context) => AddSpaceObjectRef(
      attachmentManager: attachmentManager,
    ),
  );
}

class AddSpaceObjectRef extends ConsumerWidget {
  final AttachmentsManager attachmentManager;

  const AddSpaceObjectRef({super.key, required this.attachmentManager});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.all(16),
      child: AttachOptions(
        onTapPin: () => addPinRefObject(context, ref),
        onTapEvent: () => addEventRefObject(context, ref),
        onTapTaskList: () => addTaskListRefObject(context, ref),
      ),
    );
  }

  Future<void> addPinRefObject(BuildContext context, WidgetRef ref) async {
    final sourcePinId = await selectPinDrawer(context: context);
    if (sourcePinId == null) return;
    final sourcePin = await ref.watch(pinProvider(sourcePinId).future);
    final sourceRefDetails = await sourcePin.refDetails();
    if (!context.mounted) return;
    Navigator.pop(context);
    await addRefDetailAttachment(
      context: context,
      ref: ref,
      manager: attachmentManager,
      refDetails: sourceRefDetails,
    );
  }

  Future<void> addEventRefObject(BuildContext context, WidgetRef ref) async {
    final sourceEventId = await selectEventDrawer(context: context);
    if (sourceEventId == null) return;
    final sourceEvent =
        await ref.watch(calendarEventProvider(sourceEventId).future);
    final sourceRefDetails = await sourceEvent.refDetails();
    if (!context.mounted) return;
    Navigator.pop(context);
    await addRefDetailAttachment(
      context: context,
      ref: ref,
      manager: attachmentManager,
      refDetails: sourceRefDetails,
    );
  }

  Future<void> addTaskListRefObject(BuildContext context, WidgetRef ref) async {
    final sourceTaskListId = await selectTaskListDrawer(context: context);
    if (sourceTaskListId == null) return;
    final sourceTaskList =
        await ref.watch(taskListProvider(sourceTaskListId).future);
    final sourceRefDetails = await sourceTaskList.refDetails();
    if (!context.mounted) return;
    Navigator.pop(context);
    await addRefDetailAttachment(
      context: context,
      ref: ref,
      manager: attachmentManager,
      refDetails: sourceRefDetails,
    );
  }
}
