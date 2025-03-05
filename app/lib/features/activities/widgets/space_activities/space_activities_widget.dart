import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/activities/widgets/space_activities/activity_item_widget.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

Widget? buildSpaceActivitiesWidget(
  BuildContext context,
  WidgetRef ref,
) {
  final activityDates = ref.watch(activityDatesProvider).valueOrNull;
  if (activityDates == null || activityDates.isEmpty) return null;

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SectionHeader(
        title: L10n.of(context).spaceActivities,
        showSectionBg: false,
        isShowSeeAllButton: false,
      ),
      ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: activityDates.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) =>
            buildActivitiesTimeLineItem(context, ref, activityDates[index]),
      ),
    ],
  );
}

Widget buildActivitiesTimeLineItem(
  BuildContext context,
  WidgetRef ref,
  DateTime date,
) {
  final roomIds = ref.watch(roomIdsByDateProvider(date)).valueOrNull;
  if (roomIds == null || roomIds.isEmpty) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          jiffyDateForActvity(context, date.timestamp),
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: roomIds.length,
        itemBuilder: (context, index) =>
            buildSpaceActivitiesItem(context, ref, date, roomIds[index]),
      ),
    ],
  );
}

Widget buildSpaceActivitiesItem(
  BuildContext context,
  WidgetRef ref,
  DateTime date,
  String roomId,
) {
  final activities = ref
      .watch(spaceActivitiesProviderByDate((roomId: roomId, date: date)))
      .valueOrNull;
  if (activities == null || activities.isEmpty) return const SizedBox.shrink();
  final avatarInfo = ref.watch(roomAvatarInfoProvider(roomId));
  final spaceName = avatarInfo.displayName ?? roomId;

  return ExpansionTile(
    initiallyExpanded: true,
    collapsedBackgroundColor: Colors.transparent,
    shape: const Border(),
    leading: ActerAvatar(
      options: AvatarOptions(
        avatarInfo,
        size: 24,
      ),
    ),
    title: Text(spaceName),
    children: activities
        .map((activity) => ActivityItemWidget(activity: activity))
        .toList(),
  );
}
