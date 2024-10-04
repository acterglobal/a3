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
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SpaceActionsSection extends ConsumerWidget {
  static const createChatAction = Key('space-action-create-chat');
  static const createSpaceAction = Key('space-action-create-space');

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
    bool canPostUpdate = membership?.canString('CanPostNews') == true;
    bool canChangeSetting =
        membership?.canString('CanChangeAppSettings') == true;
    bool canAddEvent = membership?.canString('CanPostEvent') == true;
    bool canAddTask = membership?.canString('CanPostTaskList') == true;
    bool canLinkSpaces = membership?.canString('CanLinkSpaces') == true;

    final children = [
      if (canPostUpdate || canChangeSetting)
        simpleActionButton(
          context: context,
          iconData: PhosphorIcons.newspaper(),
          title: L10n.of(context).addBoost,
          onPressed: () async {
            if (!canPostUpdate && canChangeSetting) {
              final result = await offerToActivateFeature(
                context: context,
                ref: ref,
                spaceId: spaceId,
                feature: SpaceFeature.boosts,
              );
              if (!result) return;
            }
            if (context.mounted) {
              context.pushNamed(
                Routes.actionAddUpdate.name,
                queryParameters: {'spaceId': spaceId},
              );
            }
          },
        ),
      if (canAddPin || canChangeSetting)
        simpleActionButton(
          context: context,
          iconData: Atlas.pin,
          title: L10n.of(context).addPin,
          onPressed: () async {
            if (!canAddPin && canChangeSetting) {
              final result = await offerToActivateFeature(
                context: context,
                ref: ref,
                spaceId: spaceId,
                feature: SpaceFeature.pins,
              );
              if (!result) return;
            }
            if (context.mounted) {
              context.pushNamed(
                Routes.createPin.name,
                queryParameters: {'spaceId': spaceId},
              );
            }
          },
        ),
      if (canAddEvent || canChangeSetting)
        simpleActionButton(
          context: context,
          iconData: Atlas.calendar_dots,
          title: L10n.of(context).addEvent,
          onPressed: () async {
            if (!canAddEvent && canChangeSetting) {
              final result = await offerToActivateFeature(
                context: context,
                ref: ref,
                spaceId: spaceId,
                feature: SpaceFeature.events,
              );
              if (!result) return;
            }
            if (context.mounted) {
              context.pushNamed(
                Routes.createEvent.name,
                queryParameters: {'spaceId': spaceId},
              );
            }
          },
        ),
      if (canAddTask || canChangeSetting)
        simpleActionButton(
          context: context,
          iconData: Atlas.list,
          title: L10n.of(context).addTask,
          onPressed: () async {
            if (!canAddEvent && canChangeSetting) {
              final result = await offerToActivateFeature(
                context: context,
                ref: ref,
                spaceId: spaceId,
                feature: SpaceFeature.tasks,
              );
              if (!result) return;
            }
            if (context.mounted) {
              showCreateUpdateTaskListBottomSheet(
                context,
                initialSelectedSpace: spaceId,
              );
            }
          },
        ),
    ];

    if (canLinkSpaces) {
      children.addAll([
        simpleActionButton(
          key: createChatAction,
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
          key: createSpaceAction,
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

  Widget simpleActionButton({
    required BuildContext context,
    required IconData iconData,
    required String title,
    required VoidCallback onPressed,
    Key? key,
  }) {
    return TextButton.icon(
      key: key,
      onPressed: onPressed,
      icon: Icon(iconData),
      label: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
