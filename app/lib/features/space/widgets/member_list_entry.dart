import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:go_router/go_router.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/services.dart';

class MemberListEntry extends ConsumerWidget {
  final Member member;
  final Member? myMembership;

  const MemberListEntry({
    super.key,
    required this.member,
    this.myMembership,
  });

  Widget submenu(BuildContext context, WidgetRef ref) {
    final List<PopupMenuEntry> submenu = [];

    submenu.add(
      PopupMenuItem(
        onTap: () {
          Clipboard.setData(
            ClipboardData(
              text: member.userId().toString(),
            ),
          );
          customMsgSnackbar(
            context,
            'Username copied to clipboard',
          );
        },
        child: const Text('Copy username'),
      ),
    );

    if (myMembership != null) {
      submenu.add(const PopupMenuDivider());
      if (myMembership!.canString('CanUpdatePowerLevels')) {
        submenu.add(
          PopupMenuItem(
            onTap: () => customMsgSnackbar(
              context,
              'Power Level change is not implemented yet',
            ),
            child: const Text('Change Power Level'),
          ),
        );
      }

      if (myMembership!.canString('CanKick')) {
        submenu.add(
          PopupMenuItem(
            onTap: () => customMsgSnackbar(
              context,
              'Kicking not yet implemented yet',
            ),
            child: const Text('Kick User'),
          ),
        );

        if (myMembership!.canString('CanBan')) {
          submenu.add(
            PopupMenuItem(
              onTap: () => customMsgSnackbar(
                context,
                'Kicking not yet implemented yet',
              ),
              child: const Text('Kick & Ban User'),
            ),
          );
        }
      }

      // if (submenu.isNotEmpty) {
      //   // add divider
      //   submenu.add(const PopupMenuDivider());
      // }
      // submenu.add(
      //   PopupMenuItem(
      //     onTap: () => _handleLeaveSpace(context, space, ref),
      //     child: const Text('Leave Space'),
      //   ),
      // );
    }

    return PopupMenuButton(
      icon: Icon(
        Icons.more_vert,
        color: Theme.of(context).colorScheme.neutral5,
      ),
      iconSize: 28,
      color: Theme.of(context).colorScheme.surface,
      itemBuilder: (BuildContext context) => submenu,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(memberProfileProvider(member));
    final userId = member.userId().toString();
    final memberStatus = member.membershipStatusStr();
    final List<Widget> trailing = [];
    debugPrint(memberStatus);
    if (memberStatus == 'Admin') {
      trailing.add(
        const Tooltip(
          message: 'Space Admin',
          child: Icon(Atlas.crown_winner_thin),
        ),
      );
    } else if (memberStatus == 'Mod') {
      trailing.add(
        const Tooltip(
          message: 'Space Moderator',
          child: Icon(Atlas.shield_star_win_thin),
        ),
      );
    } else if (memberStatus == 'Custom') {
      trailing.add(
        Tooltip(
          message: 'Custom Power Level (${member.powerLevel()})',
          child: const Icon(Atlas.star_medal_award_thin),
        ),
      );
    }
    if (myMembership != null) {
      trailing.add(submenu(context, ref));
    }
    return Card(
      child: ListTile(
        leading: profile.when(
          data: (data) => ActerAvatar(
            mode: DisplayMode.User,
            uniqueId: member.userId().toString(),
            size: 18,
            avatar: data.getAvatarImage(),
            displayName: data.displayName,
          ),
          loading: () => const Text('loading'),
          error: (e, t) => Text('loading avatar failed: $e'),
        ),
        title: profile.when(
          data: (data) => Text(data.displayName ?? userId),
          loading: () => Text(userId),
          error: (e, s) => Text('loading profile failed: $e'),
        ),
        subtitle: Text(userId),
        trailing: Row(
          children: trailing,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
        ),
      ),
    );
  }
}
