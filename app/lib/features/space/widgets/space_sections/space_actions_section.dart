import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/config/constants.dart';
import 'package:acter/router/routes.dart';
import 'package:acter/features/space/actions/activate_feature.dart';
import 'package:acter/features/space/actions/set_acter_feature.dart';
import 'package:acter/features/space/settings/pages/apps_settings_page.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter/features/tasks/sheets/create_update_task_list.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SpaceActionsSection extends ConsumerWidget {
  static const createChatAction = Key('space-action-create-chat');
  static const createSpaceAction = Key('space-action-create-space');

  final String spaceId;

  const SpaceActionsSection({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SectionHeader(
          title: L10n.of(context).actions,
          isShowSeeAllButton: false,
        ),
        actionButtons(context, ref),
        const SizedBox(height: 300),
      ],
    );
  }

  Widget actionButtons(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(roomMembershipProvider(spaceId)).valueOrNull;
    bool canChangeSetting =
        membership?.canString('CanChangeAppSettings') == true;
    bool canLinkSpaces = membership?.canString('CanLinkSpaces') == true;
    final spaceSettings =
        ref.watch(spaceAppSettingsProvider(spaceId)).valueOrNull;
    final settings = spaceSettings?.settings;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        addNewsButton(context, ref, canChangeSetting, membership, settings),
        addStoryButton(context, ref, canChangeSetting, membership, settings),
        addPinButton(context, ref, canChangeSetting, membership, settings),
        addEventButton(context, ref, canChangeSetting, membership, settings),
        addTaskActionButton(
          context,
          ref,
          canChangeSetting,
          membership,
          settings,
        ),
        if (canLinkSpaces) ...addLinkSpaceActions(context),
        if (canChangeSetting) ...addPartnershipsActions(context),
      ],
    );
  }

  List<Widget> addPartnershipsActions(BuildContext context) {
    final hostPartnershipUrl = hostPartnerShipUrl;
    return [
      if (hostPartnershipUrl != null)
        simpleActionButton(
          context: context,
          iconData: PhosphorIcons.lifebuoy(),
          title: L10n.of(context).hostSupport,
          onPressed: () => launchUrl(hostPartnershipUrl),
        ),
    ];
  }

  Widget addEventButton(
    BuildContext context,
    WidgetRef ref,
    bool canChangeSetting,
    Member? membership,
    ActerAppSettings? settings,
  ) {
    final isActive = settings?.events().active() == true;
    final canAddEvent =
        isActive && membership?.canString('CanPostEvent') == true;

    if (canAddEvent || canChangeSetting) {
      return simpleActionButton(
        context: context,
        iconData: Atlas.calendar_dots,
        title: L10n.of(context).addEvent,
        onPressed: () async {
          if (!isActive && canChangeSetting) {
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
      );
    }
    return const SizedBox.shrink();
  }

  Widget addPinButton(
    BuildContext context,
    WidgetRef ref,
    bool canChangeSetting,
    Member? membership,
    ActerAppSettings? settings,
  ) {
    final isActive = settings?.pins().active() == true;
    final canAddPin = isActive && membership?.canString('CanPostPin') == true;
    if (canAddPin || canChangeSetting) {
      return simpleActionButton(
        context: context,
        iconData: Atlas.pin,
        title: L10n.of(context).addPin,
        onPressed: () async {
          if (!isActive && canChangeSetting) {
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
      );
    }
    return const SizedBox.shrink();
  }

  Widget addNewsButton(
    BuildContext context,
    WidgetRef ref,
    bool canChangeSetting,
    Member? membership,
    ActerAppSettings? settings,
  ) {
    final isActive = settings?.news().active() == true;
    final canPostUpdate =
        isActive && membership?.canString('CanPostNews') == true;
    if (canPostUpdate || canChangeSetting) {
      return simpleActionButton(
        context: context,
        iconData: Icons.rocket_launch_sharp,
        title: L10n.of(context).addBoost,
        onPressed: () async {
          if (!isActive && canChangeSetting) {
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
      );
    }
    return const SizedBox.shrink();
  }

  Widget addStoryButton(
    BuildContext context,
    WidgetRef ref,
    bool canChangeSetting,
    Member? membership,
    ActerAppSettings? settings,
  ) {
    final isActive = settings?.stories().active() == true;
    final canPostUpdate =
        isActive && membership?.canString('CanPostStories') == true;
    if (canPostUpdate || canChangeSetting) {
      return simpleActionButton(
        context: context,
        iconData: Icons.amp_stories,
        title: L10n.of(context).addStory,
        onPressed: () async {
          if (!isActive && canChangeSetting) {
            final result = await offerToActivateFeature(
              context: context,
              ref: ref,
              spaceId: spaceId,
              feature: SpaceFeature.stories,
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
      );
    }
    return const SizedBox.shrink();
  }

  Widget addTaskActionButton(
    BuildContext context,
    WidgetRef ref,
    bool canChangeSetting,
    Member? membership,
    ActerAppSettings? settings,
  ) {
    final isActive = settings?.tasks().active() == true;
    final canAddTask =
        isActive && membership?.canString('CanPostTaskList') == true;

    if (canAddTask || canChangeSetting) {
      return simpleActionButton(
        context: context,
        iconData: Atlas.list,
        title: L10n.of(context).addTask,
        onPressed: () async {
          if (!isActive && canChangeSetting) {
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
      );
    }
    return const SizedBox.shrink();
  }

  List<Widget> addLinkSpaceActions(BuildContext context) => [
    simpleActionButton(
      key: createChatAction,
      context: context,
      iconData: Atlas.chats,
      title: L10n.of(context).addChat,
      onPressed:
          () => context.pushNamed(
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
      onPressed:
          () => context.pushNamed(
            Routes.createSpace.name,
            queryParameters: {'parentSpaceId': spaceId},
          ),
    ),
    simpleActionButton(
      context: context,
      iconData: Icons.link,
      title: L10n.of(context).linkChat,
      onPressed:
          () => context.pushNamed(
            Routes.linkChat.name,
            pathParameters: {'spaceId': spaceId},
          ),
    ),
    simpleActionButton(
      context: context,
      iconData: Icons.link,
      title: L10n.of(context).linkSpace,
      onPressed:
          () => context.pushNamed(
            Routes.linkSpace.name,
            pathParameters: {'spaceId': spaceId},
          ),
    ),
  ];

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
      label: Text(title, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
