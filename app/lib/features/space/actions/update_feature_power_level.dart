import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/space/settings/pages/apps_settings_page.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::space::settings::update_feature_level');

Future<bool> updateFeatureLevelChangeDialog(
  BuildContext context,
  int maxPowerLevel,
  int? currentPw,
  Space space,
  RoomPowerLevels powerLevels,
  String levelKey,
  String featureName,
) async {
  final lang = L10n.of(context);
  final newPowerLevel = await showDialog<int?>(
    context: context,
    builder: (BuildContext context) => _ChangePowerLevelDialog(
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

  return await updateFeatureLevel(
    lang,
    space,
    levelKey,
    featureName,
    newPowerLevel,
  );
}

Future<bool> updateFeatureLevel(
  L10n lang,
  Space space,
  String levelKey,
  String featureName,
  int? newPowerLevel,
) async {
  EasyLoading.show(status: lang.changingSettingOf(featureName));
  try {
    final res = await space.updateFeaturePowerLevels(
      levelKey,
      newPowerLevel,
    );
    EasyLoading.showToast(lang.powerLevelSubmitted(featureName));
    return res;
  } catch (e, s) {
    _log.severe('Failed to change power level of $featureName', e, s);
    EasyLoading.showError(
      lang.failedToChangePowerLevel(e),
      duration: const Duration(seconds: 3),
    );
    return false;
  }
}

class _ChangePowerLevelDialog extends StatefulWidget {
  final String featureName;
  final int? currentPowerLevel;
  final String currentPowerLevelName;

  const _ChangePowerLevelDialog({
    required this.featureName,
    required this.currentPowerLevelName,
    this.currentPowerLevel,
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
    currentMemberStatus = widget.currentPowerLevelName;
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
    final lang = L10n.of(context);
    return AlertDialog(
      title: Text(lang.updateFeaturePowerLevelDialogTitle(widget.featureName)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            currentPowerLevel != null
                ? Text(
                    lang.updateFeaturePowerLevelDialogFromTo(
                      memberStatus,
                      currentPowerLevel,
                    ),
                  )
                : Text(lang.updateFeaturePowerLevelDialogFromDefaultTo),
            Padding(
              padding: const EdgeInsets.all(5),
              child: DropdownButtonFormField(
                value: currentMemberStatus,
                onChanged: _updateMembershipStatus,
                items: [
                  DropdownMenuItem(
                    value: 'Admin',
                    child: Text(lang.powerLevelAdmin),
                  ),
                  DropdownMenuItem(
                    value: 'Mod',
                    child: Text(lang.powerLevelModerator),
                  ),
                  DropdownMenuItem(
                    value: 'Regular',
                    child: Text(lang.powerLevelRegular),
                  ),
                  DropdownMenuItem(
                    value: 'None',
                    child: Text(lang.powerLevelNone),
                  ),
                  DropdownMenuItem(
                    value: 'Custom',
                    child: Text(lang.powerLevelCustom),
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
                    labelText: lang.powerLevelCustom,
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
                        ? lang.customValueMustBeNumber
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
          child: Text(lang.cancel),
        ),
        OutlinedButton(
          onPressed: onUnset,
          child: Text(lang.unset),
        ),
        ActerPrimaryActionButton(
          onPressed: onSubmit,
          child: Text(lang.submit),
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
