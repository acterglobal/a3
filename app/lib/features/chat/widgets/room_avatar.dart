import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
    return SizedBox(
      width: avatarSize,
      height: avatarSize,
      child: ref.watch(chatProvider(roomId)).when(
            data: (convo) => chatAvatarUI(convo, ref, context),
            error: (e, s) =>
                errorAvatar(context, L10n.of(context).loadingRoomFailed(e)),
            loading: () => loadingAvatar(context),
          ),
    );
  }

  List<AvatarInfo>? renderParentsInfo(String convoId, WidgetRef ref) {
    if (!showParents) {
      return [];
    }
    final parentBadges = ref.watch(parentAvatarInfosProvider(convoId));
    return parentBadges.when(
      data: (avatarInfos) => avatarInfos,
      error: (e, s) => [],
      loading: () => [],
    );
  }

  Widget errorAvatar(BuildContext context, String error) {
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

  Widget loadingAvatar(BuildContext context, {String? error}) {
    return Skeletonizer(
      child: Container(
        color: Colors.white,
        width: avatarSize,
        height: avatarSize,
      ),
    );
  }

  Widget chatAvatarUI(Convo convo, WidgetRef ref, BuildContext context) {
    //Data Providers
    final avatarInfo = ref.watch(roomAvatarInfoProvider(convo.getRoomIdStr()));

    //Manage Avatar UI according to the avatar availability
    //Show conversations avatar if available
    //Group : Show default image if avatar is not available
    if (!convo.isDm()) {
      return ActerAvatar(
        options: AvatarOptions(
          avatarInfo,
          size: avatarSize,
          parentBadges: renderParentsInfo(roomId, ref),
          badgesSize: avatarSize / 2,
        ),
      );
    } else if (avatarInfo.avatar == null) {
      return ActerAvatar(
        options: AvatarOptions.DM(
          avatarInfo,
          size: 18,
        ),
      );
    }

    // Type == DM and no avatar: Handle avatar according to the members counts
    else {
      return dmAvatar(ref, context);
    }
  }

  Widget dmAvatar(WidgetRef ref, BuildContext context) {
    final client = ref.watch(alwaysClientProvider);
    final convoMembers = ref.watch(membersIdsProvider(roomId));
    return convoMembers.when(
      data: (members) {
        int count = members.length;

        //Show member avatar
        if (count == 1) {
          return memberAvatar(members[0], ref);
        } else if (count == 2) {
          //Show opponent member avatar
          if (members[0] != client.userId().toString()) {
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
      error: (error, stackTrace) =>
          Text(L10n.of(context).loadingMembersCountFailed(error)),
      loading: () => const CircularProgressIndicator(),
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
    final profile = ref
        .watch(memberAvatarInfoProvider((userId: members[0], roomId: roomId)));
    final secondaryProfile = ref
        .watch(memberAvatarInfoProvider((userId: members[1], roomId: roomId)));

    return ActerAvatar(
      options: AvatarOptions.GroupDM(
        profile,
        groupAvatars: [
          secondaryProfile,
          for (int i = 2; i < members.length; i++)
            AvatarInfo(
              uniqueId: members[i],
            ),
        ],
        size: avatarSize / 2,
      ),
    );
  }
}
