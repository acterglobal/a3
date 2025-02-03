enum NewsReferencesType {
  calendarEvent,
  pin,
  taskList,
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
