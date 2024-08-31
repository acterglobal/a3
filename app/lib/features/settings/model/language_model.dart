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
      'es' => const LanguageModel.spanish(),
      'pl' => const LanguageModel.polish(),
      'fr' => const LanguageModel.french(),
      'en' => const LanguageModel.english(),
      _ => const LanguageModel.english(),
    };
  }

  // We show each language in their native tongue
  const LanguageModel.english()
      : languageName = 'English',
        languageCode = 'en';

  const LanguageModel.german()
      : languageName = 'Deutsch',
        languageCode = 'de';

  const LanguageModel.french()
      : languageName = 'Français',
        languageCode = 'fr';

  const LanguageModel.polish()
      : languageName = 'Polski',
        languageCode = 'pl';

  const LanguageModel.spanish()
      : languageName = 'Espanol',
        languageCode = 'es';

  const LanguageModel.arabic()
      : languageName = 'اَلْعَرَبِيَّةُ',
        languageCode = 'ar';

  static const allLanguagesList = [
    // we show them in ehm... alphabetical order of the name in their own language
    LanguageModel.german(),
    LanguageModel.english(),
    LanguageModel.spanish(),
    LanguageModel.french(),
    LanguageModel.polish(),
    LanguageModel.arabic(),
  ];
}
