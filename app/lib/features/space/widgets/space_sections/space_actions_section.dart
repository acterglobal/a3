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
        Container(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  spaceActionButton(
                    context,
                    Atlas.pin,
                    L10n.of(context).addPin,
                  ),
                  const SizedBox(width: 12),
                  spaceActionButton(
                    context,
                    Atlas.calendar_dots,
                    L10n.of(context).addEvent,
                  ),
                  const SizedBox(width: 12),
                  spaceActionButton(
                    context,
                    Atlas.list,
                    L10n.of(context).addTask,
                  ),
                ],
              ),
              Row(
                children: [
                  spaceActionButton(
                    context,
                    Atlas.chats,
                    L10n.of(context).addChat,
                  ),
                  const SizedBox(width: 12),
                  spaceActionButton(
                    context,
                    Icons.link,
                    L10n.of(context).linkChat,
                  ),
                  const SizedBox(width: 12),
                  spaceActionButton(
                    context,
                    Icons.people,
                    L10n.of(context).addSpace,
                  ),
                ],
              ),
              Row(
                children: [
                  spaceActionButton(
                    context,
                    Icons.link,
                    L10n.of(context).linkSpace,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 300),
      ],
    );
  }

  Widget spaceActionButton(
    BuildContext context,
    IconData iconData,
    String title,
  ) {
    return OutlinedButton.icon(
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
      ),
      onPressed: () {},
      icon: Icon(iconData),
      label: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
