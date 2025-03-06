import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_item_widget.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpaceActivitiesItemWidget extends ConsumerWidget {
  const SpaceActivitiesItemWidget({
    super.key,
    required this.date,
    required this.roomId,
  });

  final DateTime date;
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref
        .watch(spaceActivitiesProviderByDate((roomId: roomId, date: date)))
        .valueOrNull;
    if (activities == null || activities.isEmpty) {
      return const SizedBox.shrink();
    }

    final avatarInfo = ref.watch(roomAvatarInfoProvider(roomId));
    final spaceName = avatarInfo.displayName ?? roomId;

    return ExpansionTile(
      initiallyExpanded: true,
      collapsedBackgroundColor: Colors.transparent,
      shape: const Border(),
      leading: ActerAvatar(options: AvatarOptions(avatarInfo, size: 24)),
      title: Text(spaceName),
      children: activities
          .map((activity) => ActivityItemWidget(activity: activity))
          .toList(),
    );
  }
}
