import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/space/settings/widgets/space_settings_menu.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:settings_ui/settings_ui.dart';

String powerLevelName(int? pw) {
  if (pw == null) {
    return 'None';
  }
  switch (pw) {
    case 100:
      return 'Admin';
    case 50:
      return 'Mod';
    case 0:
      return 'Regular';
    default:
      return 'Custom';
  }
}

class SettingsAndMembership {
  final Space space;
  final RoomPowerLevels powerLevels;
  final ActerAppSettings settings;
  final Member? member;

  const SettingsAndMembership(
      this.space, this.powerLevels, this.settings, this.member);
}

final spaceAppSettingsProvider = FutureProvider.autoDispose
    .family<SettingsAndMembership, String>((ref, spaceId) async {
  final space = await ref.watch(spaceProvider(spaceId).future);
  return SettingsAndMembership(
    space,
    await space.powerLevels(),
    await space.appSettings(),
    await ref.watch(spaceMembershipProvider(spaceId).future),
  );
});

class SpaceAppsSettingsPage extends ConsumerWidget {
  final String spaceId;
  const SpaceAppsSettingsPage({Key? key, required this.spaceId})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceSettingsWatcher = ref.watch(spaceAppSettingsProvider(spaceId));

    return WithSidebar(
      sidebar: SpaceSettingsMenu(
        spaceId: spaceId,
      ),
      child: spaceSettingsWatcher.when(
        data: (appSettingsAndMembership) {
          final appSettings = appSettingsAndMembership.settings;
          final powerLevels = appSettingsAndMembership.powerLevels;
          final defaultPw = powerLevels.eventsDefault();
          final usersDefaultPw = powerLevels.usersDefault();
          final maxPowerLevel = powerLevels.maxPowerLevel();
          String defaultDesc = 'default';
          if (usersDefaultPw >= defaultPw) {
            defaultDesc = 'not set / everyone';
          } else {
            defaultDesc = 'default [everyone has $usersDefaultPw]';
          }
          final space = appSettingsAndMembership.space;
          final canEdit = appSettingsAndMembership.member != null
              ? appSettingsAndMembership.member!
                  .canString('CanChangeAppSettings')
              : false;

          final news = appSettings.news();
          final events = appSettings.events();
          final pins = appSettings.pins();

          final moreSections = [];
          if (news.active()) {
            final currentPw = powerLevels.news();
            final pwText = maxPowerLevel == 100
                ? powerLevelName(currentPw)
                : 'Custom ($currentPw)';
            moreSections.add(
              SettingsSection(
                title: const Text('Updates'),
                tiles: [
                  SettingsTile(
                    enabled: canEdit,
                    title: const Text('Required PowerLevel'),
                    description: const Text(
                      'Minimum power level required to post news updates',
                    ),
                    trailing:
                        currentPw != null ? Text(pwText) : Text(defaultDesc),
                    onPressed: (context) async {
                      final newPowerLevel = await showDialog<int?>(
                        context: context,
                        builder: (BuildContext context) => ChangePowerLevel(
                          featureName: 'Updates',
                          currentPowerLevelName: maxPowerLevel == 100
                              ? powerLevelName(currentPw)
                              : 'Custom',
                          currentPowerLevel: currentPw,
                        ),
                      );
                      if (newPowerLevel != currentPw) {
                        await space.updateFeaturePowerLevels(
                          powerLevels.newsKey(),
                          newPowerLevel,
                        );
                        if (context.mounted) {
                          customMsgSnackbar(
                            context,
                            'Power level update for updates submitted',
                          );
                        }
                      }
                    },
                  ),
                  SettingsTile.switchTile(
                    title: const Text('Comments on Updates'),
                    description: const Text('not yet supported'),
                    enabled: false,
                    initialValue: false,
                    onToggle: (newVal) {},
                  ),
                ],
              ),
            );
          }
          if (pins.active()) {
            final currentPw = powerLevels.pins();
            final pwText = maxPowerLevel == 100
                ? powerLevelName(currentPw)
                : 'Custom ($currentPw)';
            moreSections.add(
              SettingsSection(
                title: const Text('Pin'),
                tiles: [
                  SettingsTile(
                    enabled: canEdit,
                    title: const Text('Required PowerLevel'),
                    description: const Text(
                      'Minimum power level required to post and edit pins',
                    ),
                    trailing:
                        currentPw != null ? Text(pwText) : Text(defaultDesc),
                    onPressed: (context) async {
                      final newPowerLevel = await showDialog<int?>(
                        context: context,
                        builder: (BuildContext context) => ChangePowerLevel(
                          featureName: 'Pin',
                          currentPowerLevelName: maxPowerLevel == 100
                              ? powerLevelName(currentPw)
                              : 'Custom',
                          currentPowerLevel: currentPw,
                        ),
                      );
                      if (newPowerLevel != currentPw) {
                        await space.updateFeaturePowerLevels(
                          powerLevels.pinsKey(),
                          newPowerLevel,
                        );
                        if (context.mounted) {
                          customMsgSnackbar(
                            context,
                            'Power level update for Pins submitted',
                          );
                        }
                      }
                    },
                  ),
                  SettingsTile.switchTile(
                    title: const Text('Comments on Pins'),
                    description: const Text('not yet supported'),
                    enabled: false,
                    initialValue: false,
                    onToggle: (newVal) {},
                  ),
                ],
              ),
            );
          }
          if (events.active()) {
            final currentPw = powerLevels.events();
            final pwText = maxPowerLevel == 100
                ? powerLevelName(currentPw)
                : 'Custom ($currentPw)';
            moreSections.add(
              SettingsSection(
                title: const Text('Calendar Events'),
                tiles: [
                  SettingsTile(
                    enabled: canEdit,
                    title: const Text('Admin PowerLevel'),
                    description: const Text(
                      'Minimum power level required to post calendar events',
                    ),
                    trailing:
                        currentPw != null ? Text(pwText) : Text(defaultDesc),
                    onPressed: (context) async {
                      final newPowerLevel = await showDialog<int?>(
                        context: context,
                        builder: (BuildContext context) => ChangePowerLevel(
                          featureName: 'Calendar Events',
                          currentPowerLevelName: maxPowerLevel == 100
                              ? powerLevelName(currentPw)
                              : 'Custom',
                          currentPowerLevel: currentPw,
                        ),
                      );
                      if (newPowerLevel != currentPw) {
                        await space.updateFeaturePowerLevels(
                          powerLevels.eventsKey(),
                          newPowerLevel,
                        );
                        if (context.mounted) {
                          customMsgSnackbar(
                            context,
                            'Power level update for calendar events submitted',
                          );
                        }
                      }
                    },
                  ),
                  SettingsTile(
                    enabled: false,
                    title: const Text('RSVP PowerLevel'),
                    description: const Text(
                      'Minimum power level to RSVP to calendar events',
                    ),
                    trailing: const Text('not yet implemented'),
                  ),
                  SettingsTile.switchTile(
                    title: const Text('Comments'),
                    description: const Text('not yet supported'),
                    enabled: false,
                    initialValue: false,
                    onToggle: (newVal) {},
                  ),
                ],
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(title: const Text('Apps Settings')),
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Active Apps'),
                  tiles: [
                    SettingsTile.switchTile(
                      title: const Text('Updates'),
                      enabled: canEdit,
                      description: const Text(
                        'Post space-wide updates',
                      ),
                      initialValue: news.active(),
                      onToggle: (newVal) async {
                        final updated = news.updater();
                        updated.active(newVal);
                        final builder = appSettings.updateBuilder();
                        builder.news(updated.build());
                        await space.updateAppSettings(builder);
                      },
                    ),
                    SettingsTile.switchTile(
                      title: const Text('Pins'),
                      enabled: canEdit,
                      description: const Text(
                        'Pin important information',
                      ),
                      initialValue: pins.active(),
                      onToggle: (newVal) async {
                        final updated = pins.updater();
                        updated.active(newVal);
                        final builder = appSettings.updateBuilder();
                        builder.pins(updated.build());
                        await space.updateAppSettings(builder);
                      },
                    ),
                    SettingsTile.switchTile(
                      title: const Text('Events Calendar'),
                      enabled: canEdit,
                      description: const Text(
                        'Calender with Events',
                      ),
                      initialValue: events.active(),
                      onToggle: (newVal) async {
                        final updated = events.updater();
                        updated.active(newVal);
                        final builder = appSettings.updateBuilder();
                        builder.events(updated.build());
                        await space.updateAppSettings(builder);
                      },
                    ),
                  ],
                ),
                ...moreSections,
              ],
            ),
          );
        },
        loading: () => const Center(child: Text('loading')),
        error: (e, s) => Center(
          child: Text('Error loading app settings: $e'),
        ),
      ),
    );
  }
}

class ChangePowerLevel extends StatefulWidget {
  final String featureName;
  final int? currentPowerLevel;
  final String currentPowerLevelName;
  const ChangePowerLevel({
    Key? key,
    required this.featureName,
    required this.currentPowerLevelName,
    this.currentPowerLevel,
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
                    FilteringTextInputFormatter.digitsOnly
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
          onPressed: () => Navigator.pop(context, widget.currentPowerLevel),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Unset'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
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
