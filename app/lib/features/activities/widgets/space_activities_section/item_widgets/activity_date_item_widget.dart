import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/space_activities_item_widget.dart';
import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivityDateItemWidget extends ConsumerWidget {
  final DateTime date;

  const ActivityDateItemWidget({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
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
          itemBuilder:
              (context, index) =>
                  SpaceActivitiesItemWidget(date: date, roomId: roomIds[index]),
        ),
      ],
    );
  }
}
