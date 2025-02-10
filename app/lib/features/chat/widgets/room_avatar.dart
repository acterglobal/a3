import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::chat::room_avatar');

class RoomAvatar extends ConsumerWidget {
  final String roomId;
  final double avatarSize;
  final bool showParents;

  const RoomAvatar({
    super.key,
    required this.roomId,
    this.avatarSize = 36,
    this.showParents = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //Fetch room conversations details from roomId
    final isDm =
        ref.watch(chatProvider(roomId).select((c) => c.valueOrNull?.isDm()));
    if (isDm == null) {
      // means we are still in loading
      return SizedBox(
        width: avatarSize,
        height: avatarSize,
        child: loadingAvatar(),
      );
    }
    return SizedBox(
      width: avatarSize,
      height: avatarSize,
      child: isDm == true
          ? dmAvatar(ref, context)
          : groupChatAvatarUI(ref, context),
    );
  }

  Widget errorAvatar(String error) {
    return ActerAvatar(
      options: AvatarOptions(
        AvatarInfo(
          uniqueId: 'error',
          displayName: error,
        ),
        size: avatarSize,
        badgesSize: avatarSize / 2,
      ),
    );
  }

  Widget loadingAvatar() {
    return Skeletonizer(
      child: Container(
        color: Colors.white,
        width: avatarSize,
        height: avatarSize,
      ),
    );
  }

  List<AvatarInfo>? renderParentsInfo(WidgetRef ref) {
    if (!showParents) {
      return [];
    }
    return ref.watch(parentAvatarInfosProvider(roomId)).valueOrNull ?? [];
  }

  Widget groupChatAvatarUI(WidgetRef ref, BuildContext context) {
    return ActerAvatar(
      options: AvatarOptions(
        ref.watch(roomAvatarInfoProvider(roomId)),
        size: avatarSize,
        parentBadges: renderParentsInfo(ref),
        badgesSize: avatarSize / 2,
      ),
    );
  }

  Widget dmAvatar(WidgetRef ref, BuildContext context) {
    final myUserId = ref.watch(myUserIdStrProvider);
    final membersLoader = ref.watch(membersIdsProvider(roomId));
    return membersLoader.when(
      data: (members) {
        int count = members.length;
        // handle empty list first, in case.
        if (count == 0) {
          return errorAvatar(
            L10n.of(context)
                .loadingMembersCountFailed('failed to fetched room: null'),
          );
        }
        //Show member avatar
        if (count == 1) {
          return memberAvatar(members[0], ref);
        } else if (count == 2) {
          //Show opponent member avatar
          if (members[0] != myUserId) {
            return memberAvatar(members[0], ref);
          } else {
            return memberAvatar(members[1], ref);
          }
        }

        //Show multiple member avatars
        else {
          return groupAvatarDM(members, ref);
        }
      },
      skipLoadingOnReload: false,
      error: (e, s) {
        _log.severe('Failed to load room members', e, s);
        return errorAvatar(L10n.of(context).loadingMembersCountFailed(e));
      },
      loading: () => loadingAvatar(),
    );
  }

  Widget memberAvatar(String userId, WidgetRef ref) {
    return ActerAvatar(
      options: AvatarOptions.DM(
        ref.watch(memberAvatarInfoProvider((userId: userId, roomId: roomId))),
        size: avatarSize,
      ),
    );
  }

  Widget groupAvatarDM(List<String> members, WidgetRef ref) {
    final profile = ref.watch(
      memberAvatarInfoProvider((userId: members[0], roomId: roomId)),
    );
    final secondaryProfile = ref.watch(
      memberAvatarInfoProvider((userId: members[1], roomId: roomId)),
    );

    return ActerAvatar(
      options: AvatarOptions.GroupDM(
        profile,
        groupAvatars: [
          secondaryProfile,
          for (var i = 2; i < members.length; i++)
            AvatarInfo(uniqueId: members[i]),
        ],
        size: avatarSize / 2,
      ),
    );
  }
}
