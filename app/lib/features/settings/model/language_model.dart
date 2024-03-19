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
      case 'en':
      default:
        return const LanguageModel.english();
    }
  }

  const LanguageModel.english()
      : languageName = 'English',
        languageCode = 'en';

  const LanguageModel.german()
      : languageName = 'German',
        languageCode = 'de';

  static const allLanguagesList = [
    LanguageModel.english(),
    LanguageModel.german(),
  ];
}
