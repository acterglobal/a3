import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpaceActionsSection extends ConsumerWidget {
  final String spaceId;

  const SpaceActionsSection({
    super.key,
    required this.spaceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SectionHeader(
          title: 'Actions',
          isShowSeeAllButton: false,
          onTapSeeAll: () {},
        ),
        actionButtons(context, ref),
        const SizedBox(height: 300),
      ],
    );
  }

  Widget actionButtons(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(roomMembershipProvider(spaceId));
    bool canAddPin = membership.requireValue!.canString('CanPostPin');
    bool canAddEvent = membership.requireValue!.canString('CanPostEvent');
    bool canAddTask = membership.requireValue!.canString('CanPostTaskList');
    bool canLinkSpaces = membership.requireValue!.canString('CanLinkSpaces');

    return Container(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.start,
        children: [
          spaceActionButton(
            context: context,
            iconData: Atlas.pin,
            title: L10n.of(context).addPin,
            isShow: canAddPin,
          ),
          spaceActionButton(
            context: context,
            iconData: Atlas.calendar_dots,
            title: L10n.of(context).addEvent,
            isShow: canAddEvent,
          ),
          spaceActionButton(
            context: context,
            iconData: Atlas.list,
            title: L10n.of(context).addTask,
            isShow: canAddTask,
          ),
          spaceActionButton(
            context: context,
            iconData: Atlas.chats,
            title: L10n.of(context).addChat,
            isShow: canLinkSpaces,
          ),
          spaceActionButton(
            context: context,
            iconData: Icons.people,
            title: L10n.of(context).addSpace,
            isShow: canLinkSpaces,
          ),
          spaceActionButton(
            context: context,
            iconData: Icons.link,
            title: L10n.of(context).linkChat,
            isShow: canLinkSpaces,
          ),
          spaceActionButton(
            context: context,
            iconData: Icons.link,
            title: L10n.of(context).linkSpace,
            isShow: canLinkSpaces,
          ),
        ],
      ),
    );
  }

  Widget spaceActionButton({
    required BuildContext context,
    required IconData iconData,
    required String title,
    bool isShow = true,
  }) {
    return Visibility(
      visible: isShow,
      child: TextButton.icon(
        onPressed: () {},
        icon: Icon(iconData),
        label: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
