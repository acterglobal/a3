import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget? buildSpaceActivitiesWidget(
  BuildContext context,
  WidgetRef ref,
) {
  return Column(
    children: [
      SectionHeader(
        title: L10n.of(context).spaceActivities,
        showSectionBg: false,
        isShowSeeAllButton: false,
      ),
      SpaceActivitiesWidget(),
    ],
  );
}

class SpaceActivitiesWidget extends StatefulWidget {
  const SpaceActivitiesWidget({super.key});

  @override
  State<SpaceActivitiesWidget> createState() => _SpaceActivitiesWidgetState();
}

class _SpaceActivitiesWidgetState extends State<SpaceActivitiesWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Placeholder(),
    );
  }
}
