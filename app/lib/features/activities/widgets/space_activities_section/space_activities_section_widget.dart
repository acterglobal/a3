import 'package:acter/common/actions/open_link.dart';
import 'package:acter/common/widgets/info_widget.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_date_item_widget.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget? buildSpaceActivitiesSectionWidget(BuildContext context, WidgetRef ref) {
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
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: InfoWidget(
          title: L10n.of(context).betaVersion,
          subTitle: L10n.of(context).spaceAcitivitiesBetaInfo,
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap:
              () => openLink(
                ref: ref,
                target: 'https://github.com/acterglobal/a3/issues/2597',
                lang: L10n.of(context),
              ),
        ),
      ),
      ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: activityDates.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder:
            (context, index) =>
                ActivityDateItemWidget(date: activityDates[index]),
      ),
    ],
  );
}
