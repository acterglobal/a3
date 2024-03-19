import 'package:acter/common/dialogs/block_user_dialog.dart';
import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/toolkit/menu_item_widget.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/chat/providers/create_chat_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

class _MessageUser extends ConsumerWidget {
  final Member member;
  const _MessageUser({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(alwaysClientProvider);
    final dmId = client.dmWithUser(member.userId().toString()).text();
    if (dmId != null) {
      return Center(
        child: OutlinedButton.icon(
          icon: const Icon(Atlas.chats_thin),
          onPressed: () async {
            context.pop();
            context.pushNamed(
              Routes.chatroom.name,
              pathParameters: {
                'roomId': dmId,
              },
            );
          },
          label: const Text('Message'),
        ),
      );
    } else {
      return Center(
        child: OutlinedButton.icon(
          icon: const Icon(Atlas.chats_thin),
          onPressed: () {
            final profile = member.getProfile();
            ref.read(createChatSelectedUsersProvider.notifier).state = [
              profile,
            ];
            context.pop();
            context.pushNamed(
              Routes.createChat.name,
            );
          },
          label: const Text('Start DM'),
        ),
      );
    }
  }
}

class _MemberInfoDrawerInner extends ConsumerWidget {
  final Member member;
  final ProfileData profile;
  final String memberId;
  const _MemberInfoDrawerInner({
    required this.memberId,
    required this.member,
    required this.profile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            _buildAvatarUI(context, profile),
            const SizedBox(height: 20),
            if (profile.displayName != null) _buildDisplayName(context),
            const SizedBox(height: 20),
            _buildUserName(context),
            const SizedBox(height: 20),
            ..._buildMenu(context, ref),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMenu(BuildContext context, WidgetRef ref) {
    final myUserId = ref.watch(accountProvider).userId().toString();
    final itsMe = memberId == myUserId;
    if (itsMe) {
      return [
        const Center(child: Text('This is you')),
        const SizedBox(height: 30),
      ];
    }

    // regular user
    return [
      _MessageUser(member: member),
      const SizedBox(height: 30),
      MenuItemWidget(
        iconData: Atlas.block_thin,
        title: 'Block User',
        withMenu: false,
        onTap: () async {
          await showBlockUserDialog(context, member);
          // ignore: use_build_context_synchronously
          context.pop();
        },
      ),
    ];
  }

  Widget _buildAvatarUI(
    BuildContext context,
    ProfileData memberProfile,
  ) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            width: 2,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        child: ActerAvatar(
          mode: DisplayMode.DM,
          avatarInfo: AvatarInfo(
            uniqueId: memberId,
            avatar: memberProfile.getAvatarImage(),
            displayName: memberProfile.displayName,
          ),
          size: 50,
        ),
      ),
    );
  }

  Widget _buildDisplayName(BuildContext context) {
    return Center(
      child: Text(profile.displayName!), // FIXME: make this prettier
    );
  }

  Widget _buildUserName(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        context.pop(); // close the drawer
        Clipboard.setData(
          ClipboardData(
            text: memberId,
          ),
        );
        customMsgSnackbar(
          context,
          'Username copied to clipboard',
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(memberId), // FIXME: make this prettier
          const SizedBox(width: 5),
          const Icon(Icons.copy_outlined),
        ],
      ),
    );
  }
}

class _MemberInfoSkeleton extends StatelessWidget {
  const _MemberInfoSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Skeletonizer(
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      width: 2,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  child: ActerAvatar(
                    mode: DisplayMode.DM,
                    avatarInfo: const AvatarInfo(
                      uniqueId: '@memberId:acter.global',
                    ),
                    size: 50,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Skeletonizer(
              child: Center(
                child: Text('Joe Kasiznky'),
              ),
            ),
            const SizedBox(height: 20),
            const Skeletonizer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('@memberid:acter.global'),
                  SizedBox(width: 5),
                  Icon(Icons.copy_outlined),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Skeletonizer(
              child: Center(
                child: OutlinedButton.icon(
                  icon: const Icon(Atlas.chats_thin),
                  onPressed: () {},
                  label: const Text('Start DM'),
                ),
              ),
            ),
            const Skeletonizer(
              child: Center(child: Text('This is you')),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _MemberInfoDrawer extends ConsumerWidget {
  final String roomId;
  final String memberId;
  const _MemberInfoDrawer({
    super.key,
    required this.memberId,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(roomMemberProvider((roomId: roomId, userId: memberId)))
        .when(
          data: (data) => _MemberInfoDrawerInner(
            member: data.member,
            profile: data.profile,
            memberId: memberId,
          ),
          error: (e, s) => Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text('Failed to load profile: $e'),
          ),
          loading: () => const _MemberInfoSkeleton(),
        );
  }
}

const Key memberInfoDrawer = Key('members-widgets-member-info-drawer');
Future<void> showMemberInfoDrawer({
  required BuildContext context,
  required String roomId,
  required String memberId,
  Key? key = memberInfoDrawer,
}) async {
  await showModalBottomSheet(
    showDragHandle: true,
    enableDrag: true,
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    builder: (context) => _MemberInfoDrawer(
      key: key,
      roomId: roomId,
      memberId: memberId,
    ),
  );
}
