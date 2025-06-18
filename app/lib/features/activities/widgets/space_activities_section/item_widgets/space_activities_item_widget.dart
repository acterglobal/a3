import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_item_widget.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

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

class DashedLineVertical extends StatelessWidget {
  final double? height;
  final double dashHeight;
  final double dashSpacing;
  final Color color;

  const DashedLineVertical({
    super.key,
    this.height,
    this.dashHeight = 6,
    this.dashSpacing = 5,
    this.color = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 0.5,
      height: height,
      child: CustomPaint(
        painter: _DashedLinePainter(
          dashHeight: dashHeight,
          dashSpacing: dashSpacing,
          color: color,
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final double dashHeight;
  final double dashSpacing;
  final Color color;

  _DashedLinePainter({
    required this.dashHeight,
    required this.dashSpacing,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double startY = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpacing;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
