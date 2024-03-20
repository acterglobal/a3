import 'dart:async';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _ChangePowerLevelDialog extends StatefulWidget {
  final Member member;
  final Member? myMembership;
  const _ChangePowerLevelDialog({
    required this.member,
    this.myMembership,
  });

  @override
  State<_ChangePowerLevelDialog> createState() =>
      __ChangePowerLevelDialogState();
}

class __ChangePowerLevelDialogState extends State<_ChangePowerLevelDialog> {
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

Future<int?> showChangePowerLevelDialog(
  BuildContext context,
  Member member,
  Member? myMembership,
) async {
  return await showDialog(
    context: context,
    builder: (BuildContext context) => _ChangePowerLevelDialog(
      member: member,
      myMembership: myMembership,
    ),
  );
}
