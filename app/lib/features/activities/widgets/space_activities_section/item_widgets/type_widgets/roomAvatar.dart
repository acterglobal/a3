import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/containers/activity_space_core_actions_container_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter/router/routes.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ActivityRoomAvatarItemWidget extends ConsumerWidget {
  final Activity activity;

  const ActivityRoomAvatarItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ActivitySpaceCoreActionsContainerWidget(
      onTap: () => context.pushNamed(Routes.space.name, pathParameters: {'spaceId': activity.roomIdStr()}),
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      actionTitle: L10n.of(context).updatedSpaceAvatar,
      target: activity.roomAvatar() ?? '',
      originServerTs: activity.originServerTs(),
    );
  }
}
