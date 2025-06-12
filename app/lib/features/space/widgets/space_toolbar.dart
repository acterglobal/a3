import 'package:acter/common/actions/close_room.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/router/routes.dart';
import 'package:acter/features/space/actions/set_space_title.dart';
import 'package:acter/features/space/actions/set_space_topic.dart';
import 'package:acter/features/space/dialogs/leave_space.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SpaceToolbar extends ConsumerWidget {
  static const optionsMenu = Key('space-options-menu');
  static const settingsMenu = Key('space-options-settings');
  static const leaveMenu = Key('space-options-leave');

  final String spaceId;
  final Widget? spaceTitle;

  const SpaceToolbar({super.key, required this.spaceId, this.spaceTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final membership = ref.watch(roomMembershipProvider(spaceId)).valueOrNull;
    final bookmarkState = ref.watch(spaceBookmarkProvider);
    final isBookmarked = bookmarkState[spaceId] ?? false;

    final invited =
        ref.watch(spaceInvitedMembersProvider(spaceId)).valueOrNull ?? [];
    final showInviteBtn = membership?.canString('CanInvite') == true;
    final List<PopupMenuEntry> submenu = [];
    if (membership?.canString('CanSetName') == true) {
      submenu.add(
        PopupMenuItem(
          onTap: () {
            showEditSpaceNameBottomSheet(
              context: context,
              ref: ref,
              spaceId: spaceId,
            );
          },
          child: Text(lang.editTitle),
        ),
      );
    }
    if (membership?.canString('CanSetTopic') == true) {
      submenu.add(
        PopupMenuItem(
          onTap: () {
            showEditDescriptionBottomSheet(
              context: context,
              ref: ref,
              spaceId: spaceId,
            );
          },
          child: Text(lang.editDescription),
        ),
      );
    }

    submenu.addAll([
      PopupMenuItem(
        key: settingsMenu,
        onTap:
            () => context.pushNamed(
              Routes.spaceSettings.name,
              pathParameters: {'spaceId': spaceId},
            ),
        child: Text(lang.settings),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        key: leaveMenu,
        onTap: () => showLeaveSpaceDialog(context, ref, spaceId),
        child: Text(
          lang.leaveSpace,
          style: TextStyle(color: colorScheme.error),
        ),
      ),
      if (membership?.canString('CanKick') == true &&
          membership?.canString('CanUpdateJoinRule') == true)
        PopupMenuItem(
          onTap: () => openCloseRoomDialog(context: context, roomId: spaceId),
          child: Text(
            lang.closeSpace,
            style: TextStyle(color: colorScheme.error),
          ),
        ),
    ]);

    return AppBar(
      backgroundColor: Colors.transparent,
      title: spaceTitle,
      actions: [
        if (showInviteBtn && invited.length <= 100)
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              side: BorderSide(color: colorScheme.outline),
            ),
            onPressed:
                () => context.pushNamed(
                  Routes.spaceInvite.name,
                  pathParameters: {'spaceId': spaceId},
                ),
            child: Text(
              lang.invite,
              style: TextStyle(color: colorScheme.outline),
            ),
          ),
        IconButton(
          icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
          onPressed: () async => await _bookmarkSpace(ref),
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert, key: optionsMenu),
          iconSize: 28,
          color: colorScheme.surface,
          itemBuilder: (BuildContext context) => submenu,
        ),
      ],
    );
  }

  Future<void> _bookmarkSpace(WidgetRef ref) async {
    final isBookmarked = ref.read(spaceBookmarkProvider.notifier).getBookmark(spaceId);
    await ref.read(spaceBookmarkProvider.notifier).setBookmark(spaceId, !isBookmarked);
  }
}
