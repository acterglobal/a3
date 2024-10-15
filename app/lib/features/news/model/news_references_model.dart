enum NewsReferencesType {
  calendarEvent,
  link;

  static NewsReferencesType? fromStr(String typeStr) {
    return values.asNameMap()[_toCamelCase(typeStr)];
  }
}

String _toCamelCase(String s) {
  final words = s
      .split('-')
      .map(
        (w) =>
            '${w.substring(0, 1).toUpperCase()}${w.substring(1).toLowerCase()}',
      )
      .toList();
  words[0] = words[0].toLowerCase();
  return words.join();
}

class NewsReferencesModel {
  NewsReferencesType type;
  String? id;
  String? title;

  NewsReferencesModel({
    required this.type,
    this.title,
    this.id,
  });
}

extension Expect on String? {
  /// Add `.expect(String)` on nullable String to throw on null or return the value
  String expect([Object error = 'Expect missed value']) {
    String? value = this;
    if (value == null) {
      throw error;
    }
    return value;
  }
}
