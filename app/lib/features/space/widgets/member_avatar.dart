import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::space::member_avatar');

class MemberAvatar extends ConsumerWidget {
  final String roomId;
  final String memberId;

  const MemberAvatar({super.key, required this.memberId, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(roomMemberProvider((userId: memberId, roomId: roomId)));
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.neutral4),
        shape: BoxShape.circle,
      ),
      child: profile.when(
        data: (data) => ActerAvatar(
          mode: DisplayMode.DM,
          avatarInfo: AvatarInfo(
            uniqueId: memberId,
            avatar: data.profile.getAvatarImage(),
            displayName: data.profile.displayName,
          ),
          size: 18,
        ),
        error: (err, stackTrace) {
          _log.severe("Couldn't load avatar", err, stackTrace);
          return ActerAvatar(
            mode: DisplayMode.DM,
            avatarInfo: AvatarInfo(
              uniqueId: memberId,
              displayName: memberId,
            ),
            size: 18,
          );
        },
        loading: () => Skeletonizer(
          child: ActerAvatar(
            mode: DisplayMode.DM,
            avatarInfo: AvatarInfo(uniqueId: memberId),
            size: 18,
          ),
        ),
      ),
    );
  }
}
