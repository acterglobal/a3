class LanguageModel {
  final String languageName;
  final String languageCode;

  LanguageModel({
    required this.languageName,
    required this.languageCode,
  });

  factory LanguageModel.fromCode(String? locale) {
    return switch (locale) {
      'ar' => const LanguageModel.arabic(),
      'de' => const LanguageModel.german(),
      'dk' => const LanguageModel.danish(),
      'en' => const LanguageModel.english(),
      'es' => const LanguageModel.spanish(),
      'pl' => const LanguageModel.polish(),
      'fr' => const LanguageModel.french(),
      'sw' => const LanguageModel.swahili(),
      'ur' => const LanguageModel.urdu(),
      _ => const LanguageModel.english(), // english is fallback
    };
  }

  // We show each language in their native tongue
  const LanguageModel.danish()
      : languageName = 'Dansk',
        languageCode = 'da';

  const LanguageModel.german()
      : languageName = 'Deutsch',
        languageCode = 'de';

  const LanguageModel.english()
      : languageName = 'English',
        languageCode = 'en';

  const LanguageModel.spanish()
      : languageName = 'Espanol',
        languageCode = 'es';

  const LanguageModel.french()
      : languageName = 'Français',
        languageCode = 'fr';

  const LanguageModel.polish()
      : languageName = 'Polski',
        languageCode = 'pl';

  const LanguageModel.arabic()
      : languageName = 'اَلْعَرَبِيَّةُ',
        languageCode = 'ar';

  const LanguageModel.swahili()
      : languageName = 'Swahili',
        languageCode = 'sw';

  const LanguageModel.urdu()
      : languageName = 'اردو ویکیپیڈیا',
        languageCode = 'ur';

  static const allLanguagesList = [
    // we show them in ehm... alphabetical order of the name in their own language
    LanguageModel.danish(),
    LanguageModel.german(),
    LanguageModel.english(),
    LanguageModel.spanish(),
    LanguageModel.french(),
    LanguageModel.polish(),
    LanguageModel.arabic(),
    LanguageModel.swahili(),
    LanguageModel.urdu(),
  ];
}
