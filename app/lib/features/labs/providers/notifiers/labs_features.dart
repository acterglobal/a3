import 'dart:async';
import 'package:acter/features/labs/feature_flagger.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SharedPrefFeaturesNotifier extends StateNotifier<Features<LabsFeature>> {
  late ProviderSubscription<AsyncValue<Features<LabsFeature>>> listener;
  final String instanceKey;
  final Ref ref;

  SharedPrefFeaturesNotifier(this.instanceKey, this.ref)
      : super(
          Features<LabsFeature>(
            flags: const [],
            defaultOn: LabsFeature.defaults,
          ),
        ) {
    _init();
  }

  void _init() {
    listener = ref.listen(asyncFeaturesProvider, (prev, next) {
      if (!next.hasValue) {
        // ignore and wait until it has loaded, debounce in-between
        return;
      }
      final val = next.value;
      if (val == null) throw 'next features not available';
      state = val;
    });
  }

  Future<void> newState(Features<LabsFeature> s) async {
    final prefInstance = await sharedPrefs();
    prefInstance.setString(instanceKey, s.toJson());
    final completer = Completer();
    final removeListener = addListener((_) {
      completer.complete();
    });
    final future = completer.future;
    future.whenComplete(() {
      // ensure we only fire once
      removeListener();
    });
    ref.invalidate(asyncFeaturesProvider);
    return future;
  }

  // Let’s the UI update the state of a flag
  Future<void> setActive(LabsFeature f, bool active) async {
    await newState(state.updateFlag(f, active));
  }

  // Allow higher level to reset the features flagged
  Future<void> resetFeatures(List<FeatureFlag<LabsFeature>> features) async {
    await newState(Features(flags: features, defaultOn: state.defaultOn));
  }
}
