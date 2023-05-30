import 'package:acter/common/utils/feature_flagger.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/settings/providers/notifiers/labs_features.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
