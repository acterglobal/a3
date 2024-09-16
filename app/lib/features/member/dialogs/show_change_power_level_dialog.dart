import 'dart:async';
import 'dart:math';

import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class _ChangePowerLevelDialog extends StatefulWidget {
  final Member member;
  final int maxPowerLevel;

  const _ChangePowerLevelDialog({
    required this.member,
    required this.maxPowerLevel,
  });

  @override
  State<_ChangePowerLevelDialog> createState() =>
      __ChangePowerLevelDialogState();
}

class __ChangePowerLevelDialogState extends State<_ChangePowerLevelDialog> {
  final TextEditingController dropDownMenuCtrl = TextEditingController();
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(debugLabel: 'change power level form');

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
        customValue =
            value.let((p0) => max(int.tryParse(p0) ?? 0, widget.maxPowerLevel));
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
            Text(
              L10n.of(context)
                  .changeThePowerFromTo(memberStatus, currentPowerLevel),
            ),
            Padding(
              padding: const EdgeInsets.all(5),
              child: DropdownButtonFormField(
                value: currentMemberStatus,
                onChanged: _updateMembershipStatus,
                items: [
                  if (widget.maxPowerLevel >= 100)
                    DropdownMenuItem(
                      value: 'Admin',
                      child: Text(L10n.of(context).admin),
                    ),
                  if (widget.maxPowerLevel >= 50)
                    DropdownMenuItem(
                      value: 'Mod',
                      child: Text(L10n.of(context).moderator),
                    ),
                  if (widget.maxPowerLevel >= 0)
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
                    labelText: L10n.of(context).customPowerLevel,
                  ),
                  onChanged: _newCustomLevel,
                  initialValue: currentPowerLevel.toString(),
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: true),
                  // Only numbers
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  // required field under custom
                  validator: (val) {
                    if (currentMemberStatus == 'Custom') {
                      if (val == null) {
                        return L10n.of(context)
                            .youNeedToEnterCustomValueAsNumber;
                      }
                      final level = int.tryParse(val);
                      if (level == null) {
                        return L10n.of(context)
                            .youNeedToEnterCustomValueAsNumber;
                      }
                      if (level > widget.maxPowerLevel) {
                        return L10n.of(context)
                            .youCantExceedPowerLevel(widget.maxPowerLevel);
                      }
                    }
                    return null;
                  },
                ),
              ),
            ),
          ],
          //   ),
          // ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: <Widget>[
        OutlinedButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(L10n.of(context).cancel),
        ),
        ActerPrimaryActionButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
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
          },
          child: Text(L10n.of(context).submit),
        ),
      ],
    );
  }
}

Future<int?> showChangePowerLevelDialog(
  BuildContext context,
  Member member,
  int maxPowerLevel,
) async {
  return await showDialog(
    context: context,
    builder: (BuildContext context) => _ChangePowerLevelDialog(
      member: member,
      maxPowerLevel: maxPowerLevel,
    ),
  );
}
