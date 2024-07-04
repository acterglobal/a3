import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SpaceActionsSection extends StatelessWidget {
  final String spaceId;

  const SpaceActionsSection({
    super.key,
    required this.spaceId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(
          title: 'Actions',
          isShowSeeAllButton: false,
          onTapSeeAll: () {},
        ),
        Wrap(
          children: [
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Atlas.pin),
              label: Text(
                L10n.of(context).addPin,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Atlas.calendar_dots),
              label: Text(
                L10n.of(context).addEvent,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Atlas.list),
              label: Text(
                L10n.of(context).addTask,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Atlas.chats),
              label: Text(
                L10n.of(context).addChat,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Atlas.users),
              label: Text(
                L10n.of(context).addSpace,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Atlas.link),
              label: Text(
                L10n.of(context).linkChat,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Atlas.link),
              label: Text(
                L10n.of(context).linkSpace,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 300),
      ],
    );
  }
}
