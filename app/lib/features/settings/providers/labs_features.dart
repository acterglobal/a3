import 'package:acter/common/utils/feature_flagger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum LabsFeature {
  // apps in general
  tasks,
  events,
  notes,
  pins,
  cobudget,
  polls,
  discussions,

  // searchOptions
  searchSpaces,
  ;

  static List<LabsFeature> get defaults =>
      [LabsFeature.events, LabsFeature.pins];
}

class SharedPrefFeaturesNotifier extends FeaturesNotifier<LabsFeature> {
  late SharedPreferences prefInstance;
  late VoidCallback listener;
  late String instanceKey;
  SharedPrefFeaturesNotifier(this.instanceKey, initState) : super(initState) {
    _init();
  }

  void _init() async {
    debugPrint('start of init');
    prefInstance = await SharedPreferences.getInstance();
    debugPrint('got instance');
    final currentData = prefInstance.getString(instanceKey) ?? '[]';
    final features = featureFlagsFromJson<LabsFeature>(
      json.decode(currentData),
      (name) => LabsFeature.values.byName(name),
    );
    resetFeatures(features);
    listener = addListener((s) {
      debugPrint('saving $s');
      prefInstance.setString(instanceKey, s.toJson());
    });
    debugPrint('end of init');
  }
}

final featuresProvider =
    StateNotifierProvider<SharedPrefFeaturesNotifier, Features<LabsFeature>>(
        (ref) {
  return SharedPrefFeaturesNotifier(
    'a3.labs',
    Features<LabsFeature>(
      flags: const [],
      defaultOn: LabsFeature.defaults,
    ),
  );
});
