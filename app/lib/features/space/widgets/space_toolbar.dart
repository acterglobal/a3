import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/space/dialogs/leave_space.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SpaceToolbar extends ConsumerWidget {
  static const optionsMenu = Key('space-options-menu');
  static const settingsMenu = Key('space-options-settings');
  static const leaveMenu = Key('space-options-leave');
  final String spaceId;

  const SpaceToolbar({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(roomMembershipProvider(spaceId)).valueOrNull;
    final isBookmarked = ref.watch(spaceProvider(spaceId).select(
        (asyncValue) => (asyncValue.valueOrNull?.isBookmarked()) == true,),);
    final invited =
        ref.watch(spaceInvitedMembersProvider(spaceId)).valueOrNull ?? [];
    final showInviteBtn = membership?.canString('CanInvite') == true;
    final List<PopupMenuEntry> submenu = [];
    if (membership?.canString('CanSetName') == true) {
      submenu.add(
        PopupMenuItem(
          onTap: () => context.pushNamed(
            Routes.editSpace.name,
            pathParameters: {'spaceId': spaceId},
            queryParameters: {'spaceId': spaceId},
          ),
          child: Text(L10n.of(context).editDetails),
        ),
      );
    }

    submenu.addAll([
      PopupMenuItem(
        key: settingsMenu,
        onTap: () => context.pushNamed(
          Routes.spaceSettings.name,
          pathParameters: {'spaceId': spaceId},
        ),
        child: Text(L10n.of(context).settings),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        key: leaveMenu,
        onTap: () => showLeaveSpaceDialog(context, ref, spaceId),
        child: Text(
          L10n.of(context).leaveSpace,
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    ]);

    return AppBar(
      backgroundColor: Colors.transparent,
      actions: [
        showInviteBtn && invited.length <= 100
            ? OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                onPressed: () => context.pushNamed(
                  Routes.spaceInvite.name,
                  pathParameters: {'spaceId': spaceId},
                ),
                child: Text(L10n.of(context).invite),
              )
            : const SizedBox.shrink(),
        IconButton(
          icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
          onPressed: () async =>
              await (await ref.read(spaceProvider(spaceId).future))
                  .setBookmarked(!isBookmarked),
        ),
        PopupMenuButton(
          icon: Icon(
            key: optionsMenu,
            Icons.more_vert,
            color: Theme.of(context).colorScheme.neutral5,
          ),
          iconSize: 28,
          color: Theme.of(context).colorScheme.surface,
          itemBuilder: (BuildContext context) => submenu,
        ),
      ],
    );
  }
}
