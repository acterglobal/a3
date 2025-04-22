import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_space_container_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class ActivityRoomAvatarItemWidget extends StatelessWidget {
  final Activity activity;
  const ActivityRoomAvatarItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return ActivitySpaceProfileChangeContainerWidget(
      updatedText: L10n.of(context).spaceAvatarUpdate,
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      originServerTs: activity.originServerTs(),
    );
  }
}
