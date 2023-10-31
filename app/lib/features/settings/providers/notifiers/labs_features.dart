import 'package:acter/common/utils/feature_flagger.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'dart:convert';

class SharedPrefFeaturesNotifier extends FeaturesNotifier<LabsFeature> {
  late SharedPreferences prefInstance;
  late VoidCallback listener;
  late String instanceKey;
  SharedPrefFeaturesNotifier(this.instanceKey, initState) : super(initState) {
    _init();
  }

  void _init() async {
    prefInstance = await sharedPrefs();
    final currentData = prefInstance.getString(instanceKey) ?? '[]';
    final features = featureFlagsFromJson<LabsFeature>(
      json.decode(currentData),
      (name) => LabsFeature.values.byName(name),
    );
    resetFeatures(features);
    listener = addListener((s) {
      prefInstance.setString(instanceKey, s.toJson());
    });
  }
}
