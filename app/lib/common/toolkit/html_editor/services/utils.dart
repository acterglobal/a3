// helper to convert foreign html to appflowy html
String normalizeToAppflowyHtml(String html) {
  var normalized = html;
  // replace all <br> tags with paragraph
  if (html.contains('<br>')) {
    normalized = normalized.replaceAll('<br>', '<p></p>');
  }
  // remove all <pre> tags, if there are codeblocks
  if (html.contains('<pre>')) {
    normalized = normalized.replaceAll(
      RegExp(r'<pre>|</pre>', caseSensitive: false),
      '',
    );
  }
  // convert to paragraph if not already
  if (!html.startsWith('<p>')) {
    normalized = '<p>$normalized</p>';
  }
  return normalized;
}
