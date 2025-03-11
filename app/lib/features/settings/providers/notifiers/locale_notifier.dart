import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/features/settings/model/language_model.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class LocaleNotifier extends StateNotifier<String> {
  LocaleNotifier() : super('en');

  static const languagePrefKey = 'a3.language';

  Future<void> initLanguage() async {
    final prefInstance = await sharedPrefs();
    final prefLanguageCode = prefInstance.getString(languagePrefKey);
    final deviceLanguageCode = PlatformDispatcher.instance.locale.languageCode;
    final bool isLanguageContain =
        LanguageModel.allLanguagesList
            .where((element) => element.languageCode == deviceLanguageCode)
            .toList()
            .isNotEmpty;

    if (prefLanguageCode != null) {
      _localSet(prefLanguageCode);
    } else if (isLanguageContain) {
      _localSet(deviceLanguageCode);
    }
  }

  Future<void> setLanguage(String languageCode) async {
    final prefInstance = await sharedPrefs();
    await prefInstance.setString(languagePrefKey, languageCode);
    _localSet(languageCode);
  }

  void _localSet(String languageCode) {
    state = languageCode;
    Intl.defaultLocale = languageCode;
  }
}
