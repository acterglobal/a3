import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            data: (convo) => chatAvatarUI(convo, ref),
            error: (e, s) => Center(child: Text('Loading room failed: $e')),
            loading: () => const Center(child: Text('loading...')),
          ),
    );
  }

  Widget chatAvatarUI(Convo convo, WidgetRef ref) {
    //Data Providers
    final convoProfile = ref.watch(chatProfileDataProvider(convo));
    final canonicalParent =
        ref.watch(canonicalParentProvider(convo.getRoomIdStr()));

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
            avatarsInfo: (showParent && canonicalParent.valueOrNull != null)
                ? [
                    AvatarInfo(
                      uniqueId:
                          canonicalParent.valueOrNull!.space.getRoomIdStr(),
                      displayName:
                          canonicalParent.valueOrNull!.profile.displayName ??
                              canonicalParent.valueOrNull!.space.getRoomIdStr(),
                      avatar:
                          canonicalParent.valueOrNull!.profile.getAvatarImage(),
                    ),
                  ]
                : [],
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
          return dmAvatar(ref);
        }
      },
      skipLoadingOnReload: false,
      error: (err, stackTrace) {
        debugPrint('Failed to load avatar due to $err');
        return ActerAvatar(
          mode: convo.isDm() ? DisplayMode.DM : DisplayMode.GroupChat,
          avatarInfo: AvatarInfo(
            uniqueId: convo.getRoomIdStr(),
            displayName: convo.getRoomIdStr(),
          ),
          size: avatarSize,
        );
      },
      loading: () => const CircularProgressIndicator(),
    );
  }

  Widget dmAvatar(WidgetRef ref) {
    final client = ref.watch(clientProvider);
    final convoMembers = ref.watch(chatMembersProvider(roomId));
    return convoMembers.when(
      data: (members) {
        int count = members.length;

        //Show member avatar
        if (count == 1) {
          return memberAvatar(members[0], ref);
        } else if (count == 2) {
          //Show opponent member avatar
          if (members[0].userId().toString() != client?.userId().toString()) {
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
      error: (error, stackTrace) => Text('Error loading members count $error'),
      loading: () => const CircularProgressIndicator(),
    );
  }

  Widget memberAvatar(Member member, WidgetRef ref) {
    final memberProfile = ref.watch(memberProfileProvider(member));
    return memberProfile.when(
      data: (data) => ActerAvatar(
        mode: DisplayMode.DM,
        avatarInfo: AvatarInfo(
          uniqueId: member.userId().toString(),
          displayName: data.displayName,
          avatar: data.getAvatarImage(),
        ),
        size: avatarSize,
      ),
      error: (err, stackTrace) {
        debugPrint("Couldn't load avatar");
        return ActerAvatar(
          mode: DisplayMode.DM,
          avatarInfo: AvatarInfo(
            uniqueId: member.userId().toString(),
            displayName: member.userId().toString(),
          ),
          size: avatarSize,
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget groupAvatarDM(List<Member> members, WidgetRef ref) {
    final userId = members[0].userId().toString();
    final secondaryUserId = members[1].userId().toString();
    final profile = ref.watch(memberProfileProvider(members[0]));
    final secondaryProfile = ref.watch(memberProfileProvider(members[1]));

    return profile.when(
      data: (data) {
        return ActerAvatar(
          avatarInfo: AvatarInfo(
            uniqueId: userId,
            displayName: data.displayName,
            avatar: data.getAvatarImage(),
          ),
          avatarsInfo: secondaryProfile.maybeWhen(
            data: (secData) => [
              AvatarInfo(
                uniqueId: secondaryUserId,
                displayName: secData.displayName,
                avatar: secData.getAvatarImage(),
              ),
              for (int i = 2; i < members.length; i++)
                AvatarInfo(
                  uniqueId: members[i].userId().toString(),
                ),
            ],
            orElse: () => [],
          ),
          mode: DisplayMode.GroupDM,
          size: avatarSize / 2,
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (err, st) {
        debugPrint('Couldn\'t load group Avatar');
        return ActerAvatar(
          avatarInfo: AvatarInfo(
            uniqueId: userId,
            displayName: userId,
          ),
          avatarsInfo: secondaryProfile.maybeWhen(
            data: (secData) => [
              AvatarInfo(
                uniqueId: secondaryUserId,
                displayName: secData.displayName,
                avatar: secData.getAvatarImage(),
              ),
              for (int i = 2; i < members.length; i++)
                AvatarInfo(
                  uniqueId: members[i].userId().toString(),
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
