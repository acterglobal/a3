import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter/features/tasks/sheets/create_update_task_list.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
    bool canAddPin = membership.valueOrNull?.canString('CanPostPin') == true;
    bool canAddEvent =
        membership.valueOrNull?.canString('CanPostEvent') == true;

    bool canAddTask =
        membership.valueOrNull?.canString('CanPostTaskList') == true;

    bool canLinkSpaces =
        membership.valueOrNull?.canString('CanLinkSpaces') == true;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        spaceActionButton(
          context: context,
          iconData: Atlas.pin,
          title: L10n.of(context).addPin,
          isShow: canAddPin,
          onPressed: () => context.pushNamed(
            Routes.actionAddPin.name,
            queryParameters: {'spaceId': spaceId},
          ),
        ),
        spaceActionButton(
          context: context,
          iconData: Atlas.calendar_dots,
          title: L10n.of(context).addEvent,
          isShow: canAddEvent,
          onPressed: () => context.pushNamed(
            Routes.createEvent.name,
            queryParameters: {'spaceId': spaceId},
          ),
        ),
        spaceActionButton(
          context: context,
          iconData: Atlas.list,
          title: L10n.of(context).addTask,
          isShow: canAddTask,
          onPressed: () {
            showCreateUpdateTaskListBottomSheet(
              context,
              initialSelectedSpace: spaceId,
            );
          },
        ),
        spaceActionButton(
          context: context,
          iconData: Atlas.chats,
          title: L10n.of(context).addChat,
          isShow: canLinkSpaces,
          onPressed: () => context.pushNamed(
            Routes.createChat.name,
            queryParameters: {'spaceId': spaceId},
            extra: 1,
          ),
        ),
        spaceActionButton(
          context: context,
          iconData: Icons.people,
          title: L10n.of(context).addSpace,
          isShow: canLinkSpaces,
          onPressed: () => context.pushNamed(
            Routes.createSpace.name,
            queryParameters: {'parentSpaceId': spaceId},
          ),
        ),
        spaceActionButton(
          context: context,
          iconData: Icons.link,
          title: L10n.of(context).linkChat,
          isShow: canLinkSpaces,
          onPressed: () => context.pushNamed(
            Routes.linkChat.name,
            pathParameters: {'spaceId': spaceId},
          ),
        ),
        spaceActionButton(
          context: context,
          iconData: Icons.link,
          title: L10n.of(context).linkSpace,
          isShow: canLinkSpaces,
          onPressed: () => context.pushNamed(
            Routes.linkSubspace.name,
            pathParameters: {'spaceId': spaceId},
          ),
        ),
        spaceActionButton(
          context: context,
          iconData: Atlas.globe_plant_thin,
          title: 'Integrate Climate 2025',
          isShow: canLinkSpaces,
          onPressed: () {
            final Uri url = Uri.parse('https://www.climate2025.org');
            launchUrl(url);
          },
        ),
      ],
    );
  }

  Widget spaceActionButton({
    required BuildContext context,
    required IconData iconData,
    required String title,
    VoidCallback? onPressed,
    bool isShow = true,
  }) {
    return isShow
        ? TextButton.icon(
            onPressed: onPressed,
            icon: Icon(iconData),
            label: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        : const SizedBox.shrink();
  }
}
