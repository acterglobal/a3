import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::space::actions::set_acter');

enum SpaceFeature { boosts, stories, pins, events, tasks }

extension SpaceFeatureActivator on ActerAppSettings {
  ActerAppSettingsBuilder setActivatedBuilder(
    SpaceFeature feature,
    bool newVal,
  ) {
    final builder = updateBuilder();
    switch (feature) {
      case SpaceFeature.boosts:
        final updated = news().updater();
        updated.active(newVal);
        builder.news(updated.build());
        break;
      case SpaceFeature.stories:
        final updated = stories().updater();
        updated.active(newVal);
        builder.stories(updated.build());
        break;
      case SpaceFeature.pins:
        final updated = pins().updater();
        updated.active(newVal);
        builder.pins(updated.build());
        break;
      case SpaceFeature.events:
        final updated = events().updater();
        updated.active(newVal);
        builder.events(updated.build());
        break;
      case SpaceFeature.tasks:
        final updated = tasks().updater();
        updated.active(newVal);
        builder.tasks(updated.build());
        break;
    }
    return builder;
  }
}

Future<void> setActerFeature(
  BuildContext context,
  bool newVal,
  ActerAppSettings appSettings,
  Space space,
  SpaceFeature feature,
  String featureName,
) async {
  await setActerFeatureForBuilder(
    context,
    appSettings.setActivatedBuilder(feature, newVal),
    space,
    featureName,
  );
}

Future<void> setActerFeatureForBuilder(
  BuildContext context,
  ActerAppSettingsBuilder builder,
  Space space,
  String featureName,
) async {
  final lang = L10n.of(context);
  EasyLoading.show(status: lang.changingSettingOf(featureName));
  try {
    await space.updateAppSettings(builder);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showToast(lang.changedSettingOf(featureName));
  } catch (e, s) {
    _log.severe('Failed to change setting of $featureName', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showError(
      lang.failedToToggleSettingOf(featureName, e),
      duration: const Duration(seconds: 3),
    );
  }
}
