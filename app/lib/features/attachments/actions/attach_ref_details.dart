// if generic attachment, send via manager
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/event/event_selector_drawer.dart';
import 'package:acter/common/widgets/pin/pin_selector_drawer.dart';
import 'package:acter/common/widgets/task/taskList_selector_drawer.dart';
import 'package:acter/features/attachments/actions/handle_selected_attachments.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Future<void> attachRefDetailToPin({
  required BuildContext context,
  required WidgetRef ref,
  required RefDetails refDetails,
}) async {
  final targetPinId = await selectPinDrawer(context: context);
  if (targetPinId != null) {
    final targetPinObject = await ref.read(pinProvider(targetPinId).future);
    final attachmentManager = await targetPinObject.attachments();

    //Upload ref attachment
    if (!context.mounted) return;
    await addRefDetailAttachment(
      context: context,
      ref: ref,
      manager: attachmentManager,
      refDetails: refDetails,
    );

    if (!context.mounted) return;
    context.pushNamed(Routes.pin.name, pathParameters: {'pinId': targetPinId});
  }
}

Future<void> attachRefDetailToEvent({
  required BuildContext context,
  required WidgetRef ref,
  required RefDetails refDetails,
}) async {
  final targetEventId = await selectEventDrawer(context: context);
  if (targetEventId != null) {
    final targetEventObject = await ref.read(
      calendarEventProvider(targetEventId).future,
    );
    final attachmentManager = await targetEventObject.attachments();

    //Upload ref attachment
    if (!context.mounted) return;
    addRefDetailAttachment(
      context: context,
      ref: ref,
      manager: attachmentManager,
      refDetails: refDetails,
    );

    if (!context.mounted) return;
    context.pushNamed(
      Routes.calendarEvent.name,
      pathParameters: {'calendarId': targetEventId},
    );
  }
}

Future<void> attachRefDetailToTaskList({
  required BuildContext context,
  required WidgetRef ref,
  required RefDetails refDetails,
}) async {
  final targetTaskListId = await selectTaskListDrawer(context: context);
  if (targetTaskListId != null) {
    final targetTaskListObject = await ref.read(
      taskListProvider(targetTaskListId).future,
    );
    final attachmentManager = await targetTaskListObject.attachments();

    //Upload ref attachment
    if (!context.mounted) return;
    addRefDetailAttachment(
      context: context,
      ref: ref,
      manager: attachmentManager,
      refDetails: refDetails,
    );

    if (!context.mounted) return;
    context.pushNamed(
      Routes.taskListDetails.name,
      pathParameters: {'taskListId': targetTaskListId},
    );
  }
}
