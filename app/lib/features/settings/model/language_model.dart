class LanguageModel {
  final String languageName;
  final String languageCode;

  LanguageModel({
    required this.languageName,
    required this.languageCode,
  });

  factory LanguageModel.fromCode(String? locale) {
    switch (locale) {
      case 'de':
        return const LanguageModel.german();
      case 'pl':
        return const LanguageModel.polish();
      case 'en':
      default:
        return const LanguageModel.english();
    }
  }

  // We show each language in their native tongue
  const LanguageModel.english()
      : languageName = 'English',
        languageCode = 'en';

  const LanguageModel.german()
      : languageName = 'Deutsch',
        languageCode = 'de';

  const LanguageModel.polish()
      : languageName = 'Polski',
        languageCode = 'pl';

  static const allLanguagesList = [
    // we show them in ehm... alphabetical order
    LanguageModel.german(),
    LanguageModel.english(),
    LanguageModel.polish(),
  ];
}
