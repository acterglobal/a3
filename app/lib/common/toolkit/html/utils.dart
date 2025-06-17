final linkMatcher = RegExp(
  r'(https?:\/\/|matrix:|acter:)([^\s]+)',
  multiLine: true,
  unicode: true,
);

/// A helper function that replaces simple URLs and line breaks in a simple
/// text with their html versions
String minimalMarkup(String text) => text
    .replaceAllMapped(
      linkMatcher,
      // we replace links we've found with an html version for the inner
      // rendering engine
      (match) => '<a href="${match[0]!}">${match[2]!}</a>',
    )
    .replaceAll('\n', '<br>');
