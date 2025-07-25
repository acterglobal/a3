class MarkedUpEditContent {
  final List<String> userMentions;
  final String plainText;
  final String htmlText;
  const MarkedUpEditContent({
    this.userMentions = const [],
    this.plainText = '',
    this.htmlText = '',
  });
}

final _userRegexp = RegExp(r'<###@@?(.+)###>');

MarkedUpEditContent parseSimplyMentions(String sourceText) {
  String finalPlain = sourceText;
  String finalHtml = sourceText;
  List<String> finalMentions = _userRegexp
      .allMatches(sourceText)
      .map((m) => '@${m[1]}')
      .toList();

  if (finalMentions.isNotEmpty) {
    // there were some found, we need to update the plaintext and the html
    finalPlain = sourceText.replaceAllMapped(_userRegexp, (m) => '@${m[1]}');
    finalHtml = sourceText.replaceAllMapped(
      _userRegexp,
      (m) => '<a href="matrix:u/${m[1]}">@${m[1]}</a>',
    );
  }
  // empty to start with
  return MarkedUpEditContent(
    plainText: finalPlain,
    htmlText: finalHtml,
    userMentions: finalMentions,
  );
}
