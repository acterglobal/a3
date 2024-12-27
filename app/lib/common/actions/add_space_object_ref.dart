import 'package:acter/common/widgets/event/event_selector_drawer.dart';
import 'package:acter/common/widgets/pin/pin_selector_drawer.dart';
import 'package:acter/common/widgets/share/action/share_space_object_action.dart';
import 'package:acter/common/widgets/share/widgets/attach_options.dart';
import 'package:acter/common/widgets/task/taskList_selector_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> addSpaceObjectRefDialog({
  required BuildContext context,
  SpaceObjectDetails? spaceObjectDetails,
}) async {
  await showModalBottomSheet(
    showDragHandle: true,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    builder: (context) => AddSpaceObjectRef(
      spaceObjectDetails: spaceObjectDetails,
    ),
  );
}

class AddSpaceObjectRef extends ConsumerWidget {
  final SpaceObjectDetails? spaceObjectDetails;

  const AddSpaceObjectRef({
    super.key,
    required this.spaceObjectDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.all(16),
      child: AttachOptions(
        onTapPin: () async {
          final sourcePinId = await selectPinDrawer(context: context);
          if (!context.mounted) return;
          Navigator.pop(context);
        },
        onTapEvent: () async {
          final sourceEventId = await selectEventDrawer(context: context);
          if (!context.mounted) return;
          Navigator.pop(context);
        },
        onTapTaskList: () async {
          final sourceTaskListId = await selectTaskListDrawer(context: context);
          if (!context.mounted) return;
          Navigator.pop(context);
        },
      ),
    );
  }
}
