import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

final _log = Logger('a3::chat::room_avatar');

class RoomAvatar extends ConsumerWidget {
  final String roomId;
  final double avatarSize;
  final bool showParent;

  const RoomAvatar({
    super.key,
    required this.roomId,
    this.avatarSize = 36,
    this.showParent = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //Fetch room conversations details from roomId
    return SizedBox(
      width: avatarSize,
      height: avatarSize,
      child: ref.watch(chatProvider(roomId)).when(
            data: (convo) => chatAvatarUI(convo, ref, context),
            error: (e, s) => Center(child: Text(L10n.of(context).loadingRoomFailed(e))),
            loading: () => Center(child: Text(L10n.of(context).loading)),
          ),
    );
  }

  List<AvatarInfo> renderParentInfo(String convoId, WidgetRef ref) {
    if (!showParent) {
      return [];
    }
    final canonicalParent = ref.watch(canonicalParentProvider(convoId));
    return canonicalParent.when(
      data: (parent) {
        if (parent == null) {
          return [];
        }
        final space = parent.space;
        final profile = parent.profile;

        return [
          AvatarInfo(
            uniqueId: space.getRoomIdStr(),
            displayName: profile.displayName ?? space.getRoomIdStr(),
            avatar: profile.getAvatarImage(),
          ),
        ];
      },
      error: (e, s) => [],
      loading: () => [],
    );
  }

  Widget chatAvatarUI(Convo convo, WidgetRef ref, BuildContext context) {
    //Data Providers
    final convoProfile = ref.watch(chatProfileDataProvider(convo));

    //Manage Avatar UI according to the avatar availability
    return convoProfile.when(
      data: (profile) {
        //Show conversations avatar if available
        //Group : Show default image if avatar is not available
        if (!convo.isDm()) {
          return ActerAvatar(
            mode: DisplayMode.Space,
            avatarInfo: AvatarInfo(
              uniqueId: roomId,
              displayName: profile.displayName ?? roomId,
              avatar: profile.getAvatarImage(),
            ),
            size: avatarSize,
            avatarsInfo: renderParentInfo(roomId, ref),
            badgeSize: avatarSize / 2,
          );
        } else if (profile.hasAvatar()) {
          return ActerAvatar(
            mode: DisplayMode.DM,
            avatarInfo: AvatarInfo(
              uniqueId: roomId,
              displayName: profile.displayName ?? roomId,
              avatar: profile.getAvatarImage(),
            ),
            size: 18,
          );
        }

        //Type == DM and no avatar: Handle avatar according to the members counts
        else {
          return dmAvatar(ref, context);
        }
      },
      skipLoadingOnReload: false,
      error: (err, stackTrace) {
        _log.severe('Failed to load avatar', err, stackTrace);
        return ActerAvatar(
          mode: convo.isDm() ? DisplayMode.DM : DisplayMode.GroupChat,
          avatarInfo: AvatarInfo(
            uniqueId: roomId,
            displayName: roomId,
          ),
          size: avatarSize,
        );
      },
      loading: () => Skeletonizer(
        child: ActerAvatar(
          mode: DisplayMode.DM,
          avatarInfo: AvatarInfo(uniqueId: roomId),
          size: 24,
        ),
      ),
    );
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
      error: (error, stackTrace) => Text(L10n.of(context).loadingMembersCountFailed(error)),
      loading: () => const CircularProgressIndicator(),
    );
  }

  Widget memberAvatar(String userId, WidgetRef ref) {
    final memberProfile =
        ref.watch(roomMemberProvider((userId: userId, roomId: roomId)));
    return memberProfile.when(
      data: (data) => ActerAvatar(
        mode: DisplayMode.DM,
        avatarInfo: AvatarInfo(
          uniqueId: userId,
          displayName: data.profile.displayName,
          avatar: data.profile.getAvatarImage(),
        ),
        size: avatarSize,
      ),
      error: (err, stackTrace) {
        _log.severe("Couldn't load avatar", err, stackTrace);
        return ActerAvatar(
          mode: DisplayMode.DM,
          avatarInfo: AvatarInfo(
            uniqueId: userId,
          ),
          size: avatarSize,
        );
      },
      loading: () => Skeletonizer(
        child: ActerAvatar(
          mode: DisplayMode.DM,
          avatarInfo: AvatarInfo(uniqueId: userId),
          size: avatarSize,
        ),
      ),
    );
  }

  Widget groupAvatarDM(List<String> members, WidgetRef ref) {
    final userId = members[0];
    final secondaryUserId = members[1];
    final profile =
        ref.watch(roomMemberProvider((userId: members[0], roomId: roomId)));
    final secondaryProfile =
        ref.watch(roomMemberProvider((userId: members[1], roomId: roomId)));

    return profile.when(
      data: (data) {
        return ActerAvatar(
          avatarInfo: AvatarInfo(
            uniqueId: userId,
            displayName: data.profile.displayName,
            avatar: data.profile.getAvatarImage(),
          ),
          avatarsInfo: secondaryProfile.maybeWhen(
            data: (secData) => [
              AvatarInfo(
                uniqueId: secondaryUserId,
                displayName: secData.profile.displayName,
                avatar: secData.profile.getAvatarImage(),
              ),
              for (int i = 2; i < members.length; i++)
                AvatarInfo(
                  uniqueId: members[i],
                ),
            ],
            orElse: () => [],
          ),
          mode: DisplayMode.GroupDM,
          size: avatarSize / 2,
        );
      },
      loading: () => Skeletonizer(
        child: ActerAvatar(
          mode: DisplayMode.GroupDM,
          avatarInfo: AvatarInfo(uniqueId: userId),
          size: avatarSize / 2,
        ),
      ),
      error: (err, st) {
        _log.severe('Couldn\'t load group Avatar', err, st);
        return ActerAvatar(
          avatarInfo: AvatarInfo(
            uniqueId: userId,
            displayName: userId,
          ),
          avatarsInfo: secondaryProfile.maybeWhen(
            data: (secData) => [
              AvatarInfo(
                uniqueId: secondaryUserId,
                displayName: secData.profile.displayName,
                avatar: secData.profile.getAvatarImage(),
              ),
              for (int i = 2; i < members.length; i++)
                AvatarInfo(
                  uniqueId: members[i],
                ),
            ],
            orElse: () => [],
          ),
          mode: DisplayMode.GroupDM,
        );
      },
    );
  }
}
