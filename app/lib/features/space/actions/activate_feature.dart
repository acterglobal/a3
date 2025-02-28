import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/space/actions/set_acter_feature.dart';
import 'package:acter/features/space/actions/update_feature_power_level.dart';
import 'package:acter/features/space/settings/pages/apps_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::space::actions::activate');

Future<bool> offerToActivateFeature({
  required BuildContext context,
  required WidgetRef ref,
  required String spaceId,
  required SpaceFeature feature,
}) async {
  final lang = L10n.of(context);
  EasyLoading.showInfo(lang.loading);
  try {
    final space = await ref.read(spaceProvider(spaceId).future);
    final appSettingsAndMembership = await ref.read(
      spaceAppSettingsProvider(spaceId).future,
    );
    EasyLoading.dismiss();
    if (!context.mounted) {
      return false;
    }

    final featureTitle = switch (feature) {
      SpaceFeature.boosts => lang.boosts,
      SpaceFeature.pins => lang.pins,
      SpaceFeature.events => lang.events,
      SpaceFeature.tasks => lang.tasks,
    };
    final appSettings = appSettingsAndMembership.settings;
    final powerLevels = appSettingsAndMembership.powerLevels;
    final maxPowerLevel = powerLevels.maxPowerLevel();

    final currentPowerLevel = switch (feature) {
      SpaceFeature.boosts => powerLevels.news(),
      SpaceFeature.events => powerLevels.events(),
      SpaceFeature.pins => powerLevels.pins(),
      SpaceFeature.tasks => powerLevels.tasks(),
    };

    final isAlreadyActive = switch (feature) {
      SpaceFeature.boosts => appSettings.news().active(),
      SpaceFeature.events => appSettings.events().active(),
      SpaceFeature.pins => appSettings.pins().active(),
      SpaceFeature.tasks => appSettings.tasks().active(),
    };
    final levelKey = switch (feature) {
      SpaceFeature.boosts => powerLevels.newsKey(),
      SpaceFeature.pins => powerLevels.pinsKey(),
      SpaceFeature.events => powerLevels.eventsKey(),
      SpaceFeature.tasks => powerLevels.tasksKey(),
    };

    if (isAlreadyActive) {
      // feature is already activated, forward to the power level changer
      return await updateFeatureLevelChangeDialog(
        context,
        maxPowerLevel,
        currentPowerLevel,
        space,
        powerLevels,
        levelKey,
        featureTitle,
      );
    }

    int? setPowerLevel;

    EasyLoading.dismiss();
    final shouldActivate = await showDialog<bool?>(
      context: context,
      builder:
          (BuildContext context) => _ActivateFeatureDialog(
            featureName: featureTitle,
            currentPowerLevelName:
                maxPowerLevel == 100
                    ? powerLevelName(currentPowerLevel)
                    : 'Custom',
            currentPowerLevel: currentPowerLevel,
            onPowerLevelChange: (newValue) => setPowerLevel = newValue,
          ),
    );

    if (shouldActivate != true || !context.mounted) {
      return false;
    }

    await setActerFeature(
      context,
      true,
      appSettings,
      space,
      feature,
      featureTitle,
    );

    if (setPowerLevel != currentPowerLevel) {
      await updateFeatureLevel(
        // ignore: use_build_context_synchronously
        lang,
        space,
        levelKey,
        featureTitle,
        setPowerLevel,
      );
    }

    return true;
  } catch (error, stack) {
    _log.severe('Failed to activate space feature', error, stack);
    EasyLoading.showToast(lang.error(error));
  }
  return false;
}

class _ActivateFeatureDialog extends StatefulWidget {
  final String featureName;
  final int? currentPowerLevel;
  final String currentPowerLevelName;
  final Function(int?) onPowerLevelChange;

  const _ActivateFeatureDialog({
    required this.featureName,
    required this.currentPowerLevelName,
    this.currentPowerLevel,
    required this.onPowerLevelChange,
  });

  @override
  State<_ActivateFeatureDialog> createState() => __ActivateFeatureDialogState();
}

class __ActivateFeatureDialogState extends State<_ActivateFeatureDialog> {
  final TextEditingController dropDownMenuCtrl = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(
    debugLabel: 'activate feature form',
  );

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
    final currentPowerLevel = widget.currentPowerLevel;
    final lang = L10n.of(context);
    return AlertDialog(
      title: Text(lang.activateFeatureDialogTitle(widget.featureName)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(lang.activateFeatureDialogDesc(widget.featureName)),
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
                  decoration: InputDecoration(labelText: lang.powerLevelCustom),
                  onChanged: _newCustomLevel,
                  initialValue: currentPowerLevel.toString(),
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  // Only numbers
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  // required field under custom
                  validator: (val) {
                    if (currentMemberStatus == 'Custom') {
                      if (val == null) {
                        return lang.youNeedToEnterCustomValueAsNumber;
                      }
                      if (int.tryParse(val) == null) {
                        return lang.customValueMustBeNumber;
                      }
                    }
                    return null;
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: <Widget>[
        OutlinedButton(onPressed: onCancel, child: Text(lang.cancel)),
        ActerPrimaryActionButton(
          onPressed: onSubmit,
          child: Text(lang.activate),
        ),
      ],
    );
  }

  void onCancel() {
    Navigator.pop(context, false);
  }

  void onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    final freshMemberStatus = widget.currentPowerLevelName;
    if (freshMemberStatus != currentMemberStatus) {
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
      widget.onPowerLevelChange(newValue);
    }

    Navigator.pop(context, true);
  }
}
