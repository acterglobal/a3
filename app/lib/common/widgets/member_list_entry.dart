import 'dart:async';

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/widgets/default_button.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class ChangePowerLevel extends StatefulWidget {
  final Member member;
  final Member? myMembership;
  const ChangePowerLevel({
    Key? key,
    required this.member,
    this.myMembership,
  }) : super(key: key);

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
      title: const Text('Update Power level'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Change the power level of'),
            Text(member.userId().toString()),
            // Row(
            //   children: [
            Text('from $memberStatus ($currentPowerLevel) to '),
            Padding(
              padding: const EdgeInsets.all(5),
              child: DropdownButtonFormField(
                value: currentMemberStatus,
                onChanged: _updateMembershipStatus,
                items: const [
                  DropdownMenuItem(
                    value: 'Admin',
                    child: Text('Admin'),
                  ),
                  DropdownMenuItem(
                    value: 'Mod',
                    child: Text('Moderator'),
                  ),
                  DropdownMenuItem(
                    value: 'Regular',
                    child: Text('Regular'),
                  ),
                  DropdownMenuItem(
                    value: 'Custom',
                    child: Text('Custom'),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: currentMemberStatus == 'Custom',
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: TextFormField(
                  decoration: const InputDecoration(
                    hintText: 'any number',
                    labelText: 'Custom power level',
                  ),
                  onChanged: _newCustomLevel,
                  initialValue: currentPowerLevel.toString(),
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: true),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ], // Only numbers
                  validator: (String? value) {
                    return currentMemberStatus == 'Custom' &&
                            (value == null || int.tryParse(value) == null)
                        ? 'You need to enter the custom value as a number.'
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
          child: const Text('Cancel'),
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
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

class MemberListEntry extends ConsumerWidget {
  final Member member;
  final Space? space;
  final Convo? convo;
  final Member? myMembership;

  const MemberListEntry({
    super.key,
    required this.member,
    this.space,
    this.convo,
    this.myMembership,
  });

  Future<void> blockUser(BuildContext context) async {
    final userId = member.userId().toString();
    await showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text('Block $userId'),
          content: RichText(
            textAlign: TextAlign.left,
            text: TextSpan(
              text: 'You are about to block $userId. ',
              style: const TextStyle(color: Colors.white, fontSize: 24),
              children: const <TextSpan>[
                TextSpan(
                  text:
                      "Once blocked you won't see their messages anymore and it will block their attempt to contact you directly. ",
                ),
                TextSpan(text: 'Continue?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                showAdaptiveDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) => DefaultDialog(
                    title: Text(
                      'Blocking User',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    isLoader: true,
                  ),
                );
                try {
                  await member.ignore();
                  if (!context.mounted) {
                    return;
                  }
                  context.pop();

                  showAdaptiveDialog(
                    context: context,
                    builder: (context) => DefaultDialog(
                      title: Text(
                        'User blocked. It might takes a bit before the UI reflects this update.',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      actions: <Widget>[
                        DefaultButton(
                          onPressed: () {
                            // close both dialogs
                            context.pop();
                            context.pop();
                          },
                          title: 'Okay',
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
                        'Block user failed: \n $err"',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      actions: <Widget>[
                        DefaultButton(
                          onPressed: () {
                            // close both dialogs
                            context.pop();
                            context.pop();
                          },
                          title: 'Okay',
                        ),
                      ],
                    ),
                  );
                }
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> unblockUser(BuildContext context) async {
    final userId = member.userId().toString();
    await showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text('Unblock $userId'),
          content: RichText(
            textAlign: TextAlign.left,
            text: TextSpan(
              text: 'You are about to unblock $userId.',
              style: const TextStyle(color: Colors.white, fontSize: 24),
              children: const <TextSpan>[
                TextSpan(
                  text: 'This will allow them to contact you again',
                ),
                TextSpan(text: 'Continue?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                showAdaptiveDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) => DefaultDialog(
                    title: Text(
                      'Unblocking User',
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
                        'User unblocked. It might takes a bit before the UI reflects this update.',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      actions: <Widget>[
                        DefaultButton(
                          onPressed: () {
                            // close both dialogs
                            context.pop();
                            context.pop();
                          },
                          title: 'Okay',
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
                        'Unblock user failed: \n $err"',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      actions: <Widget>[
                        DefaultButton(
                          onPressed: () {
                            // close both dialogs
                            context.pop();
                            context.pop();
                          },
                          title: 'Okay',
                        ),
                      ],
                    ),
                  );
                }
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> changePowerLevel(BuildContext context, WidgetRef ref) async {
    final newPowerlevel = await showDialog<int?>(
      context: context,
      builder: (BuildContext context) =>
          ChangePowerLevel(member: member, myMembership: myMembership),
    );
    if (newPowerlevel != null) {
      final userId = member.userId().toString();

      // We are doing as expected, but the lints triggers.
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }
      showAdaptiveDialog(
        context: context,
        builder: (context) => DefaultDialog(
          title: Text(
            'Updating Power level of $userId',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          isLoader: true,
        ),
      );
      space != null
          ? convo?.updatePowerLevel(userId, newPowerlevel)
          : space?.updatePowerLevel(userId, newPowerlevel);

      // We are doing as expected, but the lints triggers.
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      customMsgSnackbar(context, 'PowerLevel update submitted');
    }
  }

  Widget submenu(BuildContext context, WidgetRef ref) {
    final List<PopupMenuEntry> submenu = [];

    submenu.add(
      PopupMenuItem(
        onTap: () {
          Clipboard.setData(
            ClipboardData(
              text: member.userId().toString(),
            ),
          );
          customMsgSnackbar(
            context,
            'Username copied to clipboard',
          );
        },
        child: const Text('Copy username'),
      ),
    );

    if (member.isIgnored()) {
      submenu.add(
        PopupMenuItem(
          onTap: () async {
            await unblockUser(context);
          },
          child: const Text('Unblock User'),
        ),
      );
    } else {
      submenu.add(
        PopupMenuItem(
          onTap: () async {
            await blockUser(context);
          },
          child: const Text('Block User'),
        ),
      );
    }

    if (myMembership != null) {
      submenu.add(const PopupMenuDivider());
      if (myMembership!.canString('CanUpdatePowerLevels')) {
        submenu.add(
          PopupMenuItem(
            onTap: () async {
              await changePowerLevel(context, ref);
            },
            child: const Text('Change Power Level'),
          ),
        );
      }

      if (myMembership!.canString('CanKick')) {
        submenu.add(
          PopupMenuItem(
            onTap: () => customMsgSnackbar(
              context,
              'Kicking not yet implemented yet',
            ),
            child: const Text('Kick User'),
          ),
        );

        if (myMembership!.canString('CanBan')) {
          submenu.add(
            PopupMenuItem(
              onTap: () => customMsgSnackbar(
                context,
                'Kicking not yet implemented yet',
              ),
              child: const Text('Kick & Ban User'),
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
    final userId = member.userId().toString();
    final profile = ref.watch(memberProfileProvider(member));
    final memberStatus = member.membershipStatusStr();
    final List<Widget> trailing = [];
    if (member.isIgnored()) {
      trailing.add(
        const Tooltip(
          message: "You have blocked this user, you can't see their messages",
          child: Icon(Atlas.block_thin),
        ),
      );
    }
    if (memberStatus == 'Admin') {
      trailing.add(
        const Tooltip(
          message: 'Space Admin',
          child: Icon(Atlas.crown_winner_thin),
        ),
      );
    } else if (memberStatus == 'Mod') {
      trailing.add(
        const Tooltip(
          message: 'Space Moderator',
          child: Icon(Atlas.shield_star_win_thin),
        ),
      );
    } else if (memberStatus == 'Custom') {
      trailing.add(
        Tooltip(
          message: 'Custom Power Level (${member.powerLevel()})',
          child: const Icon(Atlas.star_medal_award_thin),
        ),
      );
    }
    if (myMembership != null) {
      trailing.add(submenu(context, ref));
    }
    return Card(
      child: ListTile(
        leading: profile.when(
          data: (data) => ActerAvatar(
            mode: DisplayMode.User,
            uniqueId: userId,
            size: data.hasAvatar() ? 18 : 36,
            avatar: data.getAvatarImage(),
            displayName: data.displayName,
          ),
          loading: () => ActerAvatar(
            mode: DisplayMode.User,
            uniqueId: userId,
            size: 36,
          ),
          error: (e, t) {
            debugPrint('loading avatar failed: $e');
            return ActerAvatar(
              uniqueId: userId,
              displayName: userId,
              mode: DisplayMode.User,
              size: 36,
            );
          },
        ),
        title: profile.when(
          data: (data) => Text(
            data.displayName ?? userId,
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
          loading: () => Text(
            userId,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          error: (e, s) {
            debugPrint('loading Profile failed $e');
            return const SizedBox.shrink();
          },
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
      ),
    );
  }
}
