import 'package:acter/common/widgets/room/room_avatar_builder.dart';
import 'package:acter/features/member/dialogs/show_block_user_dialog.dart';
import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/toolkit/menu_item_widget.dart';
import 'package:acter/features/member/dialogs/show_change_power_level_dialog.dart';
import 'package:acter/features/member/dialogs/show_kick_user_dialog.dart';
import 'package:acter/features/member/dialogs/show_unblock_user_dialog.dart';
import 'package:acter/features/member/widgets/member_info_skeleton.dart';
import 'package:acter/features/member/widgets/message_user_button.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

class _MemberInfoDrawerInner extends ConsumerWidget {
  final Member member;
  final ProfileData profile;
  final String memberId;
  const _MemberInfoDrawerInner({
    required this.memberId,
    required this.member,
    required this.profile,
  });

  Future<void> changePowerLevel(BuildContext context, WidgetRef ref) async {
    final roomId = member.roomIdStr();
    final userId = member.userId().toString();
    final myMembership = await ref.read(roomMembershipProvider(roomId).future);
    if (!context.mounted) return;
    final newPowerLevel =
        await showChangePowerLevelDialog(context, member, myMembership);
    if (newPowerLevel != null) {
      // We are doing as expected, but the lints triggers.
      // ignore: use_build_context_synchronously
      EasyLoading.show(
        status: 'Updating Power level of $userId',
      );
      try {
        final room = await ref.read(maybeRoomProvider(roomId).future);
        await room?.updatePowerLevel(userId, newPowerLevel);
        EasyLoading.dismiss();
        EasyLoading.showToast('PowerLevel update submitted');
      } catch (e) {
        EasyLoading.showError(
          'Failed to set power level: $e',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

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
    final myUserId = ref.watch(myUserIdStrProvider);
    final itsMe = memberId == myUserId;
    if (itsMe) {
      return [
        const Center(child: Text('This is you')),
        const SizedBox(height: 30),
      ];
    }

    return [
      MessageUserButton(member: member),
      const SizedBox(height: 30),
      (member.isIgnored())
          ? MenuItemWidget(
              iconData: Atlas.block_thin,
              title: 'Unblock User',
              withMenu: false,
              onTap: () async {
                await showUnblockUserDialog(context, member);
                if (context.mounted) {
                  context.pop();
                }
              },
            )
          : MenuItemWidget(
              iconData: Atlas.block_thin,
              title: 'Block User',
              withMenu: false,
              onTap: () async {
                await showBlockUserDialog(context, member);
                if (context.mounted) {
                  context.pop();
                }
              },
            ),
      ..._roomMenu(context, ref),
    ];
  }

  Widget _showPowerLevel(BuildContext context, VoidCallback? onTap) {
    final memberStatus = member.membershipStatusStr();
    if (memberStatus == 'Admin') {
      return Card(
        child: ListTile(
          leading: const Icon(Atlas.crown_winner_thin),
          title: const Text('Admin'),
          onTap: onTap,
        ),
      );
    } else if (memberStatus == 'Mod') {
      return Card(
        child: ListTile(
          leading: const Icon(Atlas.shield_star_win_thin),
          title: const Text('Moderator'),
          onTap: onTap,
        ),
      );
    } else {
      return Card(
        child: ListTile(
          leading: const Icon(Atlas.shield_star_win_thin),
          title: const Text('Power Level'),
          trailing: Text('${member.powerLevel()}'),
          onTap: onTap,
        ),
      );
    }
  }

  List<Widget> _roomMenu(BuildContext context, WidgetRef ref) {
    return ref.watch(roomMembershipProvider(member.roomIdStr())).when(
          data: (myMembership) {
            if (myMembership == null) {
              // showing just the power level
              return [_roomTitle(context, ref), _showPowerLevel(context, null)];
            }

            final menu = [_roomTitle(context, ref)];

            if (myMembership.canString('CanUpdatePowerLevels')) {
              menu.add(
                _showPowerLevel(
                  context,
                  () async {
                    await changePowerLevel(context, ref);
                    if (context.mounted) {
                      context.pop();
                    }
                  },
                ),
              );
            } else {
              menu.add(_showPowerLevel(context, null));
            }

            if (myMembership.canString('CanKick')) {
              menu.add(
                MenuItemWidget(
                  iconData: Atlas.medal_badge_award_thin,
                  title: 'Kick User',
                  withMenu: false,
                  onTap: () async {
                    await showKickUserDialog(context, member);
                    if (context.mounted) {
                      context.pop();
                    }
                  },
                ),
              );

              if (myMembership.canString('CanBan')) {
                menu.add(
                  MenuItemWidget(
                    iconData: Atlas.medal_badge_award_thin,
                    title: 'Kick & Ban User',
                    withMenu: false,
                    onTap: () => customMsgSnackbar(
                      context,
                      'Kicking not yet implemented yet',
                    ),
                  ),
                );
              }
            }
            return menu;
          },
          error: (e, s) => [
            _roomTitle(context, ref),
            MenuItemWidget(
              iconData: Atlas.triangle_exclamation_thin,
              title: 'Error loading: $e',
              withMenu: false,
              onTap: () {},
            ),
          ],
          loading: () => [
            _roomTitle(context, ref),
            Skeletonizer(
              child: MenuItemWidget(
                iconData: Atlas.medal_badge_award_thin,
                title: 'Change Power Level',
                withMenu: false,
                onTap: () {},
              ),
            ),
          ],
        );
  }

  Widget _roomTitle(BuildContext context, WidgetRef ref) {
    final roomId = member.roomIdStr();
    final roomData = ref.watch(briefRoomItemWithMembershipProvider(roomId));
    return ListTile(
      leading: RoomAvatarBuilder(roomId: roomId, avatarSize: 24),
      title: roomData.maybeWhen(
        data: (roomData) =>
            Text(roomData.roomProfileData.displayName ?? roomId),
        orElse: () => Text(roomId),
      ),
    );
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

class MemberInfoDrawer extends ConsumerWidget {
  final String roomId;
  final String memberId;
  const MemberInfoDrawer({
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
          loading: () => const MemberInfoSkeleton(),
        );
  }
}
