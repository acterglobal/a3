import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_space_container_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ActivityRoomTopicItemWidget extends ConsumerWidget {
  final Activity activity;
  const ActivityRoomTopicItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
   final subTitle = activity.roomTopic() ?? '';
    final memberInfo = ref.watch(
      memberAvatarInfoProvider((roomId: activity.roomIdStr(), userId: activity.senderIdStr())),
    );
    return ActivitySpaceProfileChangeContainerWidget(
      leadingWidget: Icon(PhosphorIconsRegular.pencilSimpleLine, size: 40),
      titleText: L10n.of(context).spaceDescriptionUpdate(memberInfo.displayName ?? activity.senderIdStr()), 
      subtitleWidget: Text(
        subTitle,
        style: Theme.of(context).textTheme.labelMedium,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      originServerTs: activity.originServerTs(),
    );
  }
}
