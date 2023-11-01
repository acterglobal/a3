import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoomAvatar extends ConsumerWidget {
  final String roomId;
  final double avatarSize;

  const RoomAvatar({
    super.key,
    required this.roomId,
    this.avatarSize = 36,
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

    //Manage Avatar UI according to the avatar availability
    return convoProfile.when(
      data: (profile) {
        //Show conversations avatar if available
        //Group : Show default image if avatar is not available
        if (!convo.isDm()) {
          return ActerAvatar(
            uniqueId: roomId,
            mode: DisplayMode.Space,
            displayName: profile.displayName ?? roomId,
            avatar: profile.getAvatarImage(),
            size: 18,
          );
        } else if (profile.hasAvatar()) {
          return ActerAvatar(
            uniqueId: roomId,
            mode: DisplayMode.User,
            displayName: profile.displayName ?? roomId,
            avatar: profile.getAvatarImage(),
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
          uniqueId: convo.getRoomIdStr(),
          mode: convo.isDm() ? DisplayMode.User : DisplayMode.Space,
          displayName: convo.getRoomIdStr(),
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
          return groupDMAvatarUI(members, ref);
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
        mode: DisplayMode.User,
        uniqueId: member.userId().toString(),
        size: data.hasAvatar() ? 18 : avatarSize,
        avatar: data.getAvatarImage(),
        displayName: data.displayName,
      ),
      error: (err, stackTrace) {
        debugPrint("Couldn't load avatar");
        return ActerAvatar(
          mode: DisplayMode.User,
          uniqueId: member.userId().toString(),
          size: avatarSize,
          displayName: member.userId().toString(),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget groupDMAvatarUI(List<Member> members, WidgetRef ref) {
    return Stack(
      alignment: Alignment.bottomLeft,
      clipBehavior: Clip.none,
      children: [
        memberAvatar(members[0], ref),
        Positioned(
          left: -7,
          bottom: -5,
          child: memberAvatar(members[1], ref),
        ),
        Positioned.fill(
          bottom: -5,
          child: Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: 15,
              height: 15,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: Text(
                '+${members.length - 2}',
                style: const TextStyle(fontSize: 8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
