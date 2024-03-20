import 'package:acter/features/member/dialogs/show_member_info_drawer.dart';
import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

class _MemberListInnerSkeleton extends StatelessWidget {
  const _MemberListInnerSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Skeletonizer(
        child: ActerAvatar(
          mode: DisplayMode.DM,
          avatarInfo: const AvatarInfo(
            uniqueId: 'no id given',
          ),
          size: 18,
        ),
      ),
      title: Skeletonizer(
        child: Text(
          'no id',
          style: Theme.of(context).textTheme.bodyMedium,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      subtitle: Skeletonizer(
        child: Text(
          'no id',
          style: Theme.of(context)
              .textTheme
              .labelLarge!
              .copyWith(color: Theme.of(context).colorScheme.neutral5),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class MemberListEntry extends ConsumerWidget {
  final String memberId;
  final String roomId;
  final Member? myMembership;

  const MemberListEntry({
    super.key,
    required this.memberId,
    required this.roomId,
    this.myMembership,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileData =
        ref.watch(roomMemberProvider((userId: memberId, roomId: roomId)));
    return profileData.when(
      data: (data) => _MemberListEntryInner(
        userId: memberId,
        roomId: roomId,
        member: data.member,
        profile: data.profile,
      ),
      error: (e, s) => Text('Error loading Profile: $e'),
      loading: () => const _MemberListInnerSkeleton(),
    );
  }
}

class _MemberListEntryInner extends ConsumerWidget {
  final Member member;
  final ProfileData profile;
  final String userId;
  final String roomId;

  const _MemberListEntryInner({
    required this.userId,
    required this.member,
    required this.profile,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberStatus = member.membershipStatusStr();
    final List<Widget> trailing = [];
    if (member.isIgnored()) {
      trailing.add(
        const Tooltip(
          message: "You have blocked this user, you can't see their messages",
          child: Icon(Atlas.block_thin),
        ),
      );
    }
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

    return ListTile(
      onTap: () async {
        // ignore: use_build_context_synchronously
        await showMemberInfoDrawer(
          context: context,
          roomId: roomId,
          memberId: userId,
        );
      },
      leading: ActerAvatar(
        mode: DisplayMode.DM,
        avatarInfo: AvatarInfo(
          uniqueId: userId,
          displayName: profile.displayName,
          avatar: profile.getAvatarImage(),
        ),
        size: 18,
      ),
      title: Text(
        profile.displayName ?? userId,
        style: Theme.of(context).textTheme.bodyMedium,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        userId,
        style: Theme.of(context)
            .textTheme
            .labelLarge!
            .copyWith(color: Theme.of(context).colorScheme.neutral5),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: trailing,
      ),
    );
  }
}
