import 'dart:convert';

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/utils/feature_flagger.dart';
import 'package:acter/common/utils/main.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/settings/providers/notifiers/labs_features.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final allowSentryReportingProvider =
    FutureProvider((ref) => getCanReportToSentry());

const labsKey = 'a3.labs';

final asyncFeaturesProvider =
    FutureProvider<Features<LabsFeature>>((ref) async {
  final prefInstance = await sharedPrefs();
  final currentData = prefInstance.getString(labsKey) ?? '[]';
  final features = featureFlagsFromJson<LabsFeature>(
    json.decode(currentData),
    (name) => LabsFeature.values.byName(name),
  );
  return Features<LabsFeature>(
    flags: features,
    defaultOn: LabsFeature.defaults,
  );
});

final featuresProvider =
    StateNotifierProvider<SharedPrefFeaturesNotifier, Features<LabsFeature>>(
        (ref) {
  return SharedPrefFeaturesNotifier(
    labsKey,
    ref,
  );
});

final languageProvider = StateProvider<String>((ref) => 'en');

final ignoredUsersProvider = FutureProvider<List<UserId>>((ref) async {
  final account = ref.watch(accountProvider);
  return (await account.ignoredUsers()).toList();
});

final pushersProvider = FutureProvider<List<Pusher>>((ref) async {
  final client = ref.watch(alwaysClientProvider);
  return (await client.pushers()).toList();
});

final possibleEmailToAddForPushProvider =
    FutureProvider<List<String>>((ref) async {
  final emailAddress = await ref.watch(emailAddressesProvider.future);
  if (emailAddress.confirmed.isEmpty) {
    return [];
  }
  final pushers = await ref.watch(pushersProvider.future);
  if (pushers.isEmpty) {
    return emailAddress.confirmed;
  }

  var allowedEmails = emailAddress.confirmed;
  for (final p in pushers) {
    if (p.isEmailPusher()) {
      // for each pusher, remove the email from the potential list
      final addr = p.pushkey();
      if (allowedEmails.contains(addr)) {
        allowedEmails.remove(addr);
      }
    }
  }
  return allowedEmails;
});

final isActiveProvider = StateProvider.family<bool, LabsFeature>(
  (ref, feature) => ref.watch(featuresProvider).isActive(feature),
);

final asyncIsActiveProvider =
    FutureProvider.family<bool, LabsFeature>((ref, feature) async {
  return (await ref.watch(asyncFeaturesProvider.future)).isActive(feature);
});

// helper
Future<bool> updateFeatureState(
    WidgetRef ref, LabsFeature f, bool value,) async {
  await ref.read(featuresProvider.notifier).setActive(f, value);
  return ref.read(featuresProvider).isActive(f);
}
