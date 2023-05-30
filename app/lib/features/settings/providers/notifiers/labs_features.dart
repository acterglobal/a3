import 'package:acter/common/utils/feature_flagger.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
