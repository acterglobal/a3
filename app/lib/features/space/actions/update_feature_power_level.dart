import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/space/settings/pages/apps_settings_page.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::space::settings::update_feature_level');

Future<bool> updateFeatureLevelChange(
  BuildContext context,
  int maxPowerLevel,
  int? currentPw,
  Space space,
  RoomPowerLevels powerLevels,
  String featureKey,
  String featureName,
) async {
  final newPowerLevel = await showDialog<int?>(
    context: context,
    builder: (BuildContext context) => ChangePowerLevel(
      featureName: featureName,
      currentPowerLevelName:
          maxPowerLevel == 100 ? powerLevelName(currentPw) : 'Custom',
      currentPowerLevel: currentPw,
    ),
  );
  if (newPowerLevel == currentPw) return false;
  if (!context.mounted) {
    EasyLoading.dismiss();
    return true;
  }
  EasyLoading.show(status: L10n.of(context).changingSettingOf(featureName));
  try {
    final res = await space.updateFeaturePowerLevels(
      featureKey,
      newPowerLevel,
    );
    if (!context.mounted) {
      EasyLoading.dismiss();
      return res;
    }
    EasyLoading.showToast(L10n.of(context).powerLevelSubmitted(featureName));
    return res;
  } catch (e, s) {
    _log.severe('Failed to change power level of $featureName', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
    } else {
      EasyLoading.showError(
        L10n.of(context).failedToChangePowerLevel(e),
        duration: const Duration(seconds: 3),
      );
    }
    return false;
  }
}

class ChangePowerLevel extends StatefulWidget {
  final String featureName;
  final int? currentPowerLevel;
  final String currentPowerLevelName;

  const ChangePowerLevel({
    super.key,
    required this.featureName,
    required this.currentPowerLevelName,
    this.currentPowerLevel,
  });

  @override
  State<ChangePowerLevel> createState() => _ChangePowerLevelState();
}

class _ChangePowerLevelState extends State<ChangePowerLevel> {
  final TextEditingController dropDownMenuCtrl = TextEditingController();
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(debugLabel: 'change power level form');

  String? currentMemberStatus;
  int? customValue;

  @override
  void initState() {
    super.initState();
    setState(() => currentMemberStatus = widget.currentPowerLevelName);
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
    final memberStatus = widget.currentPowerLevelName;
    final currentPowerLevel = widget.currentPowerLevel;
    return AlertDialog(
      title: const Text('Update Power level'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Change the power level of'),
            Text(widget.featureName),
            // Row(
            //   children: [
            currentPowerLevel != null
                ? Text('from $memberStatus ($currentPowerLevel) to ')
                : const Text('from default to'),
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
                    value: 'None',
                    child: Text('None'),
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
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: <Widget>[
        OutlinedButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          onPressed: onUnset,
          child: const Text('Unset'),
        ),
        ActerPrimaryActionButton(
          onPressed: onSubmit,
          child: const Text('Submit'),
        ),
      ],
    );
  }

  void onCancel() {
    Navigator.pop(context, widget.currentPowerLevel);
  }

  void onUnset() {
    Navigator.pop(context, null);
  }

  void onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    final freshMemberStatus = widget.currentPowerLevelName;
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

    if (widget.currentPowerLevel == newValue) {
      // nothing to be done.
      newValue = null;
    }

    Navigator.pop(context, newValue);
  }
}
