import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/space/actions/activate_feature.dart';
import 'package:acter/features/space/actions/set_acter_feature.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter/features/tasks/sheets/create_update_task_list.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
          title: L10n.of(context).actions,
          isShowSeeAllButton: false,
          onTapSeeAll: () {},
        ),
        actionButtons(context, ref),
        const SizedBox(height: 300),
      ],
    );
  }

  Widget actionButtons(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(roomMembershipProvider(spaceId)).valueOrNull;
    bool canAddPin = membership?.canString('CanPostPin') == true;
    bool canChangeSetting =
        membership?.canString('CanChangeAppSettings') == true;
    bool canAddEvent = membership?.canString('CanPostEvent') == true;
    bool canAddTask = membership?.canString('CanPostTaskList') == true;
    bool canLinkSpaces = membership?.canString('CanLinkSpaces') == true;

    final children = [
      if (canAddPin)
        simpleActionButton(
          context: context,
          iconData: Atlas.pin,
          title: L10n.of(context).addPin,
          onPressed: () => context.pushNamed(
            Routes.createPin.name,
            queryParameters: {'spaceId': spaceId},
          ),
        )
      else if (canChangeSetting)
        askToActivateButton(
          context: context,
          iconData: Atlas.pin,
          title: L10n.of(context).addPin,
          ref: ref,
          feature: SpaceFeature.pins,
          andThen: () async {
            await context.pushNamed(
              Routes.createPin.name,
              queryParameters: {'spaceId': spaceId},
            );
          },
        ),
      if (canAddEvent)
        simpleActionButton(
          context: context,
          iconData: Atlas.calendar_dots,
          title: L10n.of(context).addEvent,
          onPressed: () => context.pushNamed(
            Routes.createEvent.name,
            queryParameters: {'spaceId': spaceId},
          ),
        )
      else if (canChangeSetting)
        askToActivateButton(
          context: context,
          iconData: Atlas.calendar_dots,
          title: L10n.of(context).addEvent,
          ref: ref,
          feature: SpaceFeature.events,
          andThen: () => context.pushNamed(
            Routes.createEvent.name,
            queryParameters: {'spaceId': spaceId},
          ),
        ),
      if (canAddTask)
        simpleActionButton(
          context: context,
          iconData: Atlas.list,
          title: L10n.of(context).addTask,
          onPressed: () => showCreateUpdateTaskListBottomSheet(
            context,
            initialSelectedSpace: spaceId,
          ),
        )
      else if (canChangeSetting)
        askToActivateButton(
          context: context,
          iconData: Atlas.list,
          title: L10n.of(context).addTask,
          ref: ref,
          feature: SpaceFeature.tasks,
          andThen: () => showCreateUpdateTaskListBottomSheet(
            context,
            initialSelectedSpace: spaceId,
          ),
        ),
    ];

    if (canLinkSpaces) {
      children.addAll([
        simpleActionButton(
          context: context,
          iconData: Atlas.chats,
          title: L10n.of(context).addChat,
          onPressed: () => context.pushNamed(
            Routes.createChat.name,
            queryParameters: {'spaceId': spaceId},
            extra: 1,
          ),
        ),
        simpleActionButton(
          context: context,
          iconData: Icons.people,
          title: L10n.of(context).addSpace,
          onPressed: () => context.pushNamed(
            Routes.createSpace.name,
            queryParameters: {'parentSpaceId': spaceId},
          ),
        ),
        simpleActionButton(
          context: context,
          iconData: Icons.link,
          title: L10n.of(context).linkChat,
          onPressed: () => context.pushNamed(
            Routes.linkChat.name,
            pathParameters: {'spaceId': spaceId},
          ),
        ),
        simpleActionButton(
          context: context,
          iconData: Icons.link,
          title: L10n.of(context).linkSpace,
          onPressed: () => context.pushNamed(
            Routes.linkSubspace.name,
            pathParameters: {'spaceId': spaceId},
          ),
        ),
      ]);
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.start,
      children: children,
    );
  }

  Widget askToActivateButton({
    required BuildContext context,
    required IconData iconData,
    required String title,
    required VoidCallback andThen,
    required WidgetRef ref,
    required SpaceFeature feature,
  }) {
    return TextButton.icon(
      onPressed: () async {
        if (await offerToActivateFeature(
          context: context,
          ref: ref,
          spaceId: spaceId,
          feature: feature,
        )) {
          andThen();
        }
      },
      icon: Icon(iconData),
      label: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget simpleActionButton({
    required BuildContext context,
    required IconData iconData,
    required String title,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(iconData),
      label: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
