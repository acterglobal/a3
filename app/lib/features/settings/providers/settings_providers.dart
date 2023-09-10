import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/utils/feature_flagger.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/settings/providers/notifiers/labs_features.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
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

final ignoredUsersProvider = FutureProvider<List<UserId>>((ref) async {
  final account = await ref.watch(accountProvider.future);
  return (await account.ignoredUsers()).toList();
});
