import 'dart:async';

import 'package:acter/common/dialogs/block_user_dialog.dart';
import 'package:acter/common/dialogs/member_info_drawer.dart';
import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ChangePowerLevel extends StatefulWidget {
  final Member member;
  final Member? myMembership;

  const ChangePowerLevel({
    super.key,
    required this.member,
    this.myMembership,
  });

  @override
  State<ChangePowerLevel> createState() => _ChangePowerLevelState();
}

class _ChangePowerLevelState extends State<ChangePowerLevel> {
  final TextEditingController dropDownMenuCtrl = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? currentMemberStatus;
  int? customValue;

  @override
  void initState() {
    super.initState();
    currentMemberStatus = widget.member.membershipStatusStr();
  }

  void _updateMembershipStatus(String? value) {
    if (mounted) {
      setState(() => currentMemberStatus = value);
    }
  }

  void _newCustomLevel(String? value) {
    if (mounted) {
      setState(() {
        if (value != null) {
          customValue = int.tryParse(value);
        } else {
          customValue = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final memberStatus = member.membershipStatusStr();
    final currentPowerLevel = member.powerLevel();
    return AlertDialog(
      title: Text(L10n.of(context).updatePowerLevel),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(L10n.of(context).changeThePowerLevelOf),
            Text(member.userId().toString()),
            // Row(
            //   children: [
            Text(
              '${L10n.of(context).from} $memberStatus ($currentPowerLevel) ${L10n.of(context).to} ',
            ),
            Padding(
              padding: const EdgeInsets.all(5),
              child: DropdownButtonFormField(
                value: currentMemberStatus,
                onChanged: _updateMembershipStatus,
                items: [
                  DropdownMenuItem(
                    value: 'Admin',
                    child: Text(L10n.of(context).admin),
                  ),
                  DropdownMenuItem(
                    value: 'Mod',
                    child: Text(L10n.of(context).moderator),
                  ),
                  DropdownMenuItem(
                    value: 'Regular',
                    child: Text(L10n.of(context).regular),
                  ),
                  DropdownMenuItem(
                    value: 'Custom',
                    child: Text(L10n.of(context).custom),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: currentMemberStatus == 'Custom',
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: TextFormField(
                  decoration: InputDecoration(
                    hintText: L10n.of(context).anyNumber,
                    labelText: L10n.of(context).customPowerLevel(''),
                  ),
                  onChanged: _newCustomLevel,
                  initialValue: currentPowerLevel.toString(),
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: true),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  // Only numbers
                  validator: (String? value) {
                    return currentMemberStatus == 'Custom' &&
                            (value == null || int.tryParse(value) == null)
                        ? L10n.of(context).youNeedToEnterCustomValueAsNumber
                        : null;
                  },
                ),
              ),
            ),
          ],
          //   ),
          // ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(L10n.of(context).cancel),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final freshMemberStatus = widget.member.membershipStatusStr();
              if (freshMemberStatus == currentMemberStatus) {
                // nothing to do, all the same.
                Navigator.pop(context, null);
                return;
              }
              int? newValue;
              if (currentMemberStatus == 'Admin') {
                newValue = 100;
              } else if (currentMemberStatus == 'Mod') {
                newValue = 50;
              } else if (currentMemberStatus == 'Regular') {
                newValue = 0;
              } else {
                newValue = customValue ?? 0;
              }

              if (currentPowerLevel == newValue) {
                // nothing to be done.
                newValue = null;
              }

              Navigator.pop(context, newValue);
              return;
            }
          },
          child: Text(L10n.of(context).submit),
        ),
      ],
    );
  }
}

class _MemberListInnerSkeleton extends StatelessWidget {
  const _MemberListInnerSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Skeletonizer(
        child: ActerAvatar(
          mode: DisplayMode.DM,
          avatarInfo: AvatarInfo(
            uniqueId: L10n.of(context).noIdGiven,
          ),
          size: 18,
        ),
      ),
      title: Skeletonizer(
        child: Text(
          L10n.of(context).noId,
          style: Theme.of(context).textTheme.bodyMedium,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      subtitle: Skeletonizer(
        child: Text(
          L10n.of(context).noId,
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
      error: (e, s) => Text('${L10n.of(context).errorLoading('profile')}: $e'),
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

  Future<void> blockUser(BuildContext context) async {
    await showBlockUserDialog(context, member);
  }

  Future<void> unblockUser(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text('${L10n.of(context).unblock} $userId'),
          content: RichText(
            textAlign: TextAlign.left,
            text: TextSpan(
              text: L10n.of(context).youAreAboutToUnblock(userId),
              style: const TextStyle(color: Colors.white, fontSize: 24),
              children: <TextSpan>[
                TextSpan(
                  text: L10n.of(context).thisWillAllowThemToContactYouAgain,
                ),
                TextSpan(text: L10n.of(context).continueText('?')),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => context.pop(),
              child: Text(L10n.of(context).no),
            ),
            TextButton(
              onPressed: () async {
                showAdaptiveDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) => DefaultDialog(
                    title: Text(
                      L10n.of(context).unblockingUser,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    isLoader: true,
                  ),
                );
                try {
                  await member.unignore();
                  if (!context.mounted) {
                    return;
                  }
                  context.pop();

                  showAdaptiveDialog(
                    context: context,
                    builder: (context) => DefaultDialog(
                      title: Text(
                        L10n.of(context).userUnblockedTitle,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      actions: <Widget>[
                        ElevatedButton(
                          onPressed: () {
                            // close both dialogs
                            context.pop();
                            context.pop();
                          },
                          child: Text(L10n.of(context).okay),
                        ),
                      ],
                    ),
                  );
                } catch (err) {
                  if (!context.mounted) {
                    return;
                  }
                  showAdaptiveDialog(
                    context: context,
                    builder: (context) => DefaultDialog(
                      title: Text(
                        '${L10n.of(context).unblockUserFailed}: \n $err"',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      actions: <Widget>[
                        ElevatedButton(
                          onPressed: () {
                            // close both dialogs
                            context.pop();
                            context.pop();
                          },
                          child: Text(L10n.of(context).okay),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: Text(L10n.of(context).yes),
            ),
          ],
        );
      },
    );
  }

  Future<void> changePowerLevel(BuildContext context, WidgetRef ref) async {
    final myMembership = await ref.read(roomMembershipProvider(roomId).future);
    if (!context.mounted) return;
    final newPowerlevel = await showDialog<int?>(
      context: context,
      builder: (BuildContext context) => ChangePowerLevel(
        member: member,
        myMembership: myMembership,
      ),
    );
    if (newPowerlevel != null) {
      // We are doing as expected, but the lints triggers.
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }
      showAdaptiveDialog(
        context: context,
        builder: (context) => DefaultDialog(
          title: Text(
            L10n.of(context).updatingPowerLevelOf(userId),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          isLoader: true,
        ),
      );
      final room = await ref.read(maybeRoomProvider(roomId).future);
      await room?.updatePowerLevel(userId, newPowerlevel);

      // We are doing as expected, but the lints triggers.
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      customMsgSnackbar(context, L10n.of(context).powerLevelUpdateSubmitted);
    }
  }

  Widget submenu(BuildContext context, WidgetRef ref) {
    final myMembership = ref.watch(roomMembershipProvider(roomId)).valueOrNull;
    final List<PopupMenuEntry> submenu = [];

    submenu.add(
      PopupMenuItem(
        onTap: () {
          Clipboard.setData(
            ClipboardData(
              text: userId,
            ),
          );
          customMsgSnackbar(
            context,
            L10n.of(context).usernameCopiedToClipboard,
          );
        },
        child: Text(L10n.of(context).copyUsername),
      ),
    );

    if (member.isIgnored()) {
      submenu.add(
        PopupMenuItem(
          onTap: () async {
            await unblockUser(context);
          },
          child: Text(L10n.of(context).unblockUser),
        ),
      );
    } else {
      submenu.add(
        PopupMenuItem(
          onTap: () async {
            await blockUser(context);
          },
          child: Text(L10n.of(context).blockUser),
        ),
      );
    }

    if (myMembership != null) {
      submenu.add(const PopupMenuDivider());
      if (myMembership.canString('CanUpdatePowerLevels')) {
        submenu.add(
          PopupMenuItem(
            onTap: () async {
              await changePowerLevel(context, ref);
            },
            child: Text(L10n.of(context).changePowerLevel),
          ),
        );
      }

      if (myMembership.canString('CanKick')) {
        submenu.add(
          PopupMenuItem(
            onTap: () => customMsgSnackbar(
              context,
              L10n.of(context).kickingNotYetImplementedYet,
            ),
            child: Text(L10n.of(context).kickUser),
          ),
        );

        if (myMembership.canString('CanBan')) {
          submenu.add(
            PopupMenuItem(
              onTap: () => customMsgSnackbar(
                context,
                L10n.of(context).kickingNotYetImplementedYet,
              ),
              child: Text(L10n.of(context).kickAndBanUser),
            ),
          );
        }
      }
    }

    return PopupMenuButton(
      icon: Icon(
        Icons.more_vert,
        color: Theme.of(context).colorScheme.neutral5,
      ),
      iconSize: 28,
      color: Theme.of(context).colorScheme.surface,
      itemBuilder: (BuildContext context) => submenu,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberStatus = member.membershipStatusStr();
    final List<Widget> trailing = [];
    if (member.isIgnored()) {
      trailing.add(
        Tooltip(
          message: L10n.of(context).youHaveBlockedThisUser,
          child: const Icon(Atlas.block_thin),
        ),
      );
    }
    if (memberStatus == 'Admin') {
      trailing.add(
        Tooltip(
          message: L10n.of(context).spaceAdmin,
          child: const Icon(Atlas.crown_winner_thin),
        ),
      );
    } else if (memberStatus == 'Mod') {
      trailing.add(
        Tooltip(
          message: L10n.of(context).spaceModerator,
          child: const Icon(Atlas.shield_star_win_thin),
        ),
      );
    } else if (memberStatus == 'Custom') {
      trailing.add(
        Tooltip(
          message: L10n.of(context).customPowerLevel('${member.powerLevel()}'),
          child: const Icon(Atlas.star_medal_award_thin),
        ),
      );
    }
    trailing.add(submenu(context, ref));

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
