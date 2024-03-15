import 'package:acter/features/settings/model/language_model.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const languagePrefKey = 'a3.language';

Future<void> initLanguage(WidgetRef ref) async {
  final prefLanguageCode = await getLanguage();
  final deviceLanguageCode = PlatformDispatcher.instance.locale.languageCode;
  final bool isLanguageContain = LanguageModel.allLanguagesList
      .contains(LanguageModel.fromCode(deviceLanguageCode));
  if (prefLanguageCode == null && isLanguageContain) {
    await setLanguage(deviceLanguageCode);
    ref.read(languageProvider.notifier).update((state) => deviceLanguageCode);
  } else if (prefLanguageCode != null) {
    ref.read(languageProvider.notifier).update(
          (state) => prefLanguageCode,
        );
  }
}

Future<void> setLanguage(String languageCode) async {
  final prefInstance = await sharedPrefs();
  await prefInstance.setString(languagePrefKey, languageCode);
}

Future<String?> getLanguage() async {
  final prefInstance = await sharedPrefs();
  return prefInstance.getString(languagePrefKey);
}
