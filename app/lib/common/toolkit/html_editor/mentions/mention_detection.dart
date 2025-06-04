import 'package:acter/features/deep_linking/parse_acter_uri.dart';
import 'package:acter/features/deep_linking/types.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

UriParseResult? getMentionForInsert(TextInsert text) {
  final attributes = text.attributes;
  if (attributes == null) {
    return null;
  }

  final href = attributes[AppFlowyRichTextKeys.href] as String?;
  if (href == null) return null;

  try {
    final uri = Uri.tryParse(href);
    if (uri == null) {
      return null;
    }
    return parseActerUri(uri);
  } catch (error) {
    return null;
  }
}
