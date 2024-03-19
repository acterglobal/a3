import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/utils/feature_flagger.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/settings/providers/notifiers/labs_features.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

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

// helper
bool updateFeatureState(ref, f, value) {
  ref.read(featuresProvider.notifier).setActive(f, value);
  return value;
}
