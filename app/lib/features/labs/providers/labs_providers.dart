import 'dart:convert';

import 'package:acter/features/labs/feature_flagger.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/notifiers/labs_features.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const labsKey = 'a3.labs';

final asyncFeaturesProvider = FutureProvider<Features<LabsFeature>>((
  ref,
) async {
  final prefInstance = await sharedPrefs();
  final currentData = prefInstance.getString(labsKey) ?? '[]';
  final features = featureFlagsFromJson<LabsFeature>(
    json.decode(currentData),
    (name) => LabsFeature.values.byName(name),
    throwOnMissing: false, // we want to ignore missing features
  );
  return Features<LabsFeature>(
    flags: features,
    defaultOn: LabsFeature.defaults,
  );
});

final featuresProvider =
    StateNotifierProvider<SharedPrefFeaturesNotifier, Features<LabsFeature>>((
      ref,
    ) {
      return SharedPrefFeaturesNotifier(labsKey, ref);
    });

final isActiveProvider = StateProvider.family<bool, LabsFeature>(
  (ref, feature) => ref.watch(featuresProvider).isActive(feature),
);

final asyncIsActiveProvider = FutureProvider.family<bool, LabsFeature>((
  ref,
  feature,
) async {
  return (await ref.watch(asyncFeaturesProvider.future)).isActive(feature);
});

// helper
Future<bool> updateFeatureState(
  WidgetRef ref,
  LabsFeature f,
  bool value,
) async {
  await ref.read(featuresProvider.notifier).setActive(f, value);
  return ref.read(isActiveProvider(f));
}
