import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_item_widget.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:acter/common/widgets/dashed_line_vertical.dart';

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
    final spaceActivitiesLoader = ref.watch(
      spaceActivitiesProviderByDate((roomId: roomId, date: date)),
    );

    return spaceActivitiesLoader.when(
      data:
          (spaceActivities) =>
              buildSpaceActivitiesItemUI(context, ref, spaceActivities),
      error: (error, stack) => const SizedBox.shrink(),
      loading: () => const SpaceActivitiesSkeleton(),
    );
  }

  Widget buildSpaceActivitiesItemUI(
    BuildContext context,
    WidgetRef ref,
    List<Activity> activities,
  ) {
    final avatarInfo = ref.watch(roomAvatarInfoProvider(roomId));
    final spaceName = avatarInfo.displayName ?? roomId;
    return ExpansionTile(
      initiallyExpanded: true,
      collapsedBackgroundColor: Colors.transparent,
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      leading: ActerAvatar(options: AvatarOptions(avatarInfo, size: 24)),
      title: Text(spaceName),
      children:
          activities
              .asMap()
              .entries
              .map((entry) {
                final activity = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DashedLineVertical(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: ActivityItemWidget(activity: activity)),
                      ],
                    ),
                  ),
                );
              })
              .toList(),
    );
  }
}

class SpaceActivitiesSkeleton extends StatelessWidget {
  const SpaceActivitiesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ListView(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: [listItem(), listItem(), listItem(), listItem(), listItem()],
      ),
    );
  }

  Widget listItem() {
    return const ListTile(
      leading: Icon(Atlas.bell, size: 60),
      title: Text('Title Title Title Title Title'),
      subtitle: Text(
        'Sub-title Sub-title Sub-title Sub-title Sub-title Sub-title Sub-title',
      ),
    );
  }
}
