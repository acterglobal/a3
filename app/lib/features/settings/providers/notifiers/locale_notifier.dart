import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/features/settings/model/language_model.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:acter/l10n/generated/l10n.dart';

class LocaleRelativeDateTime extends RelativeDateTime {
  final L10n locale;

  LocaleRelativeDateTime(this.locale);

  @override
  String prefixAgo() => locale.localePrefixAgo;

  @override
  String prefixFromNow() => locale.localePrefixFromNow;

  @override
  String suffixAgo() => locale.localeSuffixAgo;

  @override
  String suffixFromNow() => locale.localeSuffixFromNow;

  @override
  String lessThanOneMinute(int seconds) => locale.localeLessThanOneMinute;

  @override
  String aboutAMinute(int minutes) => locale.localeAboutAMinute;

  @override
  String minutes(int minutes) => locale.localeMinutes(minutes);

  @override
  String aboutAnHour(int minutes) => locale.localeAboutAnHour;

  @override
  String hours(int hours) => locale.localeHours(hours);

  @override
  String aDay(int hours) => locale.localeADay;

  @override
  String days(int days) => locale.localeDays(days);

  @override
  String aboutAMonth(int days) => locale.localeAboutAMonth;

  @override
  String months(int months) => locale.localeMonths(months);

  @override
  String aboutAYear(int year) => locale.localeAboutAYear;

  @override
  String years(int years) => locale.localeYears(years);

  @override
  String wordSeparator() => locale.localeWordSeparator;

  Ordinals ordinals() => Ordinals(
    first: locale.localeOrdinalFirst,
    second: locale.localeOrdinalSecond,
    third: locale.localeOrdinalThird,
    nth: locale.localeOrdinalNth,
  );

  StartOfWeek startOfWeek() => StartOfWeek.monday;
}

class LocaleNotifier extends StateNotifier<String> {
  LocaleNotifier() : super('en');

  static const languagePrefKey = 'a3.language';

  Future<void> initLanguage() async {
    final prefInstance = await sharedPrefs();
    final prefLanguageCode = prefInstance.getString(languagePrefKey);
    final deviceLanguageCode = PlatformDispatcher.instance.locale.languageCode;
    final bool isLanguageContain = LanguageModel.allLanguagesList
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
