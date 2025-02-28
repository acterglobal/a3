import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/menu_item_widget.dart';
import 'package:acter/common/widgets/room/room_avatar_builder.dart';
import 'package:acter/features/deep_linking/widgets/qr_code_button.dart';
import 'package:acter/features/member/dialogs/show_block_user_dialog.dart';
import 'package:acter/features/member/dialogs/show_change_power_level_dialog.dart';
import 'package:acter/features/member/dialogs/show_kick_and_ban_user_dialog.dart';
import 'package:acter/features/member/dialogs/show_kick_user_dialog.dart';
import 'package:acter/features/member/dialogs/show_unblock_user_dialog.dart';
import 'package:acter/features/member/widgets/member_info_skeleton.dart';
import 'package:acter/features/users/widgets/message_user_button.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::member::member_info_drawer');

class _MemberInfoDrawerInner extends ConsumerWidget {
  final Member member;
  final String memberId;
  final bool isShowActions;

  const _MemberInfoDrawerInner({
    required this.memberId,
    required this.member,
    required this.isShowActions,
  });

  Future<void> changePowerLevel(BuildContext context, WidgetRef ref) async {
    final lang = L10n.of(context);
    final roomId = member.roomIdStr();
    final userId = member.userId().toString();
    final myMembership = await ref.read(roomMembershipProvider(roomId).future);
    if (!context.mounted) return;

    final newPowerLevel = await showChangePowerLevelDialog(
      context,
      member,
      myMembership?.powerLevel() ?? 0,
    );
    if (newPowerLevel == null) return;

    if (!context.mounted) return;
    EasyLoading.show(status: lang.updatingPowerLevelOf(userId));
    try {
      final room = await ref.read(maybeRoomProvider(roomId).future);
      await room?.updatePowerLevel(userId, newPowerLevel);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(lang.powerLevelUpdateSubmitted);
    } catch (e, s) {
      _log.severe('Failed to change power level', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.failedToChangePowerLevel(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarInfo = ref.watch(
      memberAvatarInfoProvider((userId: memberId, roomId: member.roomIdStr())),
    );
    final dispName = avatarInfo.displayName;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            _buildAvatarUI(context, avatarInfo),
            const SizedBox(height: 20),
            if (dispName != null)
              Center(
                child: Text(dispName), // FIXME: make this prettier
              ),
            const SizedBox(height: 20),
            _buildUserName(context, avatarInfo),
            const SizedBox(height: 20),
            ..._buildMenu(context, ref),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMenu(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final myUserId = ref.watch(myUserIdStrProvider);
    final itsMe = memberId == myUserId;
    if (itsMe) {
      return [
        Center(child: Text(lang.itsYou)),
        const SizedBox(height: 30),
        if (isShowActions) ..._roomMenu(context, ref),
      ];
    }

    return [
      MessageUserButton(userId: memberId, profile: member.getProfile()),
      const SizedBox(height: 30),
      member.isIgnored()
          ? MenuItemWidget(
            iconData: Atlas.block_thin,
            title: lang.unblockUser,
            withMenu: false,
            onTap: () async {
              await showUnblockUserDialog(context, member);
            },
          )
          : MenuItemWidget(
            iconData: Atlas.block_thin,
            title: lang.blockUser,
            withMenu: false,
            onTap: () async {
              await showBlockUserDialog(context, member);
            },
          ),
      if (isShowActions) ..._roomMenu(context, ref),
    ];
  }

  Widget _showPowerLevel(BuildContext context, VoidCallback? onTap) {
    final lang = L10n.of(context);
    final memberStatus = member.membershipStatusStr();
    if (memberStatus == 'Admin') {
      return Card(
        child: ListTile(
          leading: const Icon(Atlas.crown_winner_thin),
          title: Text(lang.admin),
          onTap: onTap,
        ),
      );
    } else if (memberStatus == 'Mod') {
      return Card(
        child: ListTile(
          leading: const Icon(Atlas.shield_star_win_thin),
          title: Text(lang.moderator),
          onTap: onTap,
        ),
      );
    } else {
      return Card(
        child: ListTile(
          leading: const Icon(Atlas.shield_star_win_thin),
          title: Text(lang.powerLevel),
          trailing: Text(member.powerLevel().toString()),
          onTap: onTap,
        ),
      );
    }
  }

  List<Widget> _roomMenu(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final roomId = member.roomIdStr();
    final membershipLoader = ref.watch(roomMembershipProvider(roomId));
    return membershipLoader.when(
      data: (membership) {
        if (membership == null) {
          // showing just the power level
          return [_roomTitle(context, ref), _showPowerLevel(context, null)];
        }

        final menu = [_roomTitle(context, ref)];

        if (membership.canString('CanUpdatePowerLevels')) {
          menu.add(
            _showPowerLevel(context, () async {
              await changePowerLevel(context, ref);
              if (context.mounted) Navigator.pop(context);
            }),
          );
        } else {
          menu.add(_showPowerLevel(context, null));
        }

        if (membership.canString('CanKick')) {
          menu.add(
            MenuItemWidget(
              iconData: Icons.eject_outlined,
              title: lang.kickUser,
              withMenu: false,
              onTap: () async {
                await showKickUserDialog(context, member);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          );

          if (membership.canString('CanBan')) {
            menu.add(
              MenuItemWidget(
                iconData: Icons.gpp_bad_outlined,
                title: lang.kickAndBanUser,
                withMenu: false,
                onTap: () async {
                  await showKickAndBanUserDialog(context, member);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            );
          }
        }
        return menu;
      },
      error: (e, s) {
        _log.severe('Failed to load room membership', e, s);
        return [
          _roomTitle(context, ref),
          MenuItemWidget(
            iconData: Atlas.triangle_exclamation_thin,
            title: lang.loadingFailed(e),
            withMenu: false,
            onTap: () {},
          ),
        ];
      },
      loading:
          () => [
            _roomTitle(context, ref),
            Skeletonizer(
              child: MenuItemWidget(
                iconData: Atlas.medal_badge_award_thin,
                title: lang.changePowerLevel,
                withMenu: false,
                onTap: () {},
              ),
            ),
          ],
    );
  }

  Widget _roomTitle(BuildContext context, WidgetRef ref) {
    final roomId = member.roomIdStr();
    final roomName =
        ref.watch(roomDisplayNameProvider(roomId)).valueOrNull ?? roomId;
    return ListTile(
      leading: RoomAvatarBuilder(roomId: roomId, avatarSize: 24),
      title: Text(roomName),
    );
  }

  Widget _buildAvatarUI(BuildContext context, AvatarInfo memberAvatarInfo) {
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
          options: AvatarOptions.DM(
            AvatarInfo(
              uniqueId: memberId,
              avatar: memberAvatarInfo.avatar,
              displayName: memberAvatarInfo.displayName,
            ),
            size: 50,
          ),
        ),
      ),
    );
  }

  Widget _buildUserName(BuildContext context, AvatarInfo memberAvatarInfo) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context); // close the drawer
        await Clipboard.setData(ClipboardData(text: memberId));
        if (!context.mounted) return;
        EasyLoading.showToast(L10n.of(context).usernameCopiedToClipboard);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(memberId), // FIXME: make this prettier
          const SizedBox(width: 5),
          const Icon(PhosphorIconsLight.copy),
          const SizedBox(width: 5),
          QrCodeButton(
            qrCodeData: 'matrix:u/${memberId.substring(1)}?action=chat',
            qrTitle: ListTile(
              leading: ActerAvatar(options: AvatarOptions.DM(memberAvatarInfo)),
              title: Text(
                memberAvatarInfo.displayName ?? '',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              subtitle: Text(memberId, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}

class MemberInfoDrawer extends ConsumerWidget {
  final String roomId;
  final String memberId;
  final bool isShowActions;

  const MemberInfoDrawer({
    super.key,
    required this.memberId,
    required this.roomId,
    required this.isShowActions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberLoader = ref.watch(
      memberProvider((roomId: roomId, userId: memberId)),
    );
    return memberLoader.when(
      data:
          (member) => _MemberInfoDrawerInner(
            member: member,
            memberId: memberId,
            isShowActions: isShowActions,
          ),
      error: (e, s) {
        _log.severe('Failed to load room member', e, s);
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Text(L10n.of(context).errorLoadingProfile(e)),
        );
      },
      loading: () => const MemberInfoSkeleton(),
    );
  }
}
