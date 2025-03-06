import 'package:acter/common/actions/open_link.dart';
import 'package:acter/common/toolkit/buttons/user_chip.dart';
import 'package:acter/features/deep_linking/parse_acter_uri.dart';
import 'package:acter/features/deep_linking/types.dart';
import 'package:acter/features/deep_linking/widgets/inline_item_preview.dart';
import 'package:acter/features/room/widgets/room_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart'
    as html;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/dom.dart' as dom;

class RenderHtmlNg extends ConsumerWidget {
  final String text;
  final TextStyle? defaultTextStyle;
  final TextStyle? linkTextStyle;
  final bool shrinkToFit;
  final int? maxLines;
  final bool renderNewlines;
  final String roomId;
  const RenderHtmlNg({
    super.key,
    required this.text,
    this.defaultTextStyle,
    this.linkTextStyle,
    this.shrinkToFit = false,
    this.maxLines,
    this.renderNewlines = false,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return html.HtmlWidget(
      text,
      onTapUrl: (url) => openLink(ref, url, context),
      textStyle: defaultTextStyle,
      customWidgetBuilder: (dom.Element element) {
        if (element.localName?.toLowerCase() == 'a') {
          final href = element.attributes['href'];
          if (href == null) {
            return null;
          }
          final uri = Uri.tryParse(href);
          if (uri == null) {
            return null;
          }
          try {
            final parsed = parseActerUri(uri);
            if (parsed.titleMatches(element.text)) {
              return _buildPill(parsed);
            } else {
              return null;
            }
          } on SchemeNotSupported {
            return null;
          } on IncorrectHashError {
            return null;
          } on MissingUserError {
            return null;
          } on ObjectNotSupported {
            return null;
          } on ParsingFailed {
            return null;
          }
        }
        return null;
      },
    );
  }

  Widget? _buildPill(UriParseResult parsed) => switch (parsed.type) {
    (LinkType.userId) => html.InlineCustomWidget(
      child: UserChip(roomId: roomId, memberId: parsed.target),
    ),
    (LinkType.roomId) => html.InlineCustomWidget(
      child: RoomChip(
        roomId: parsed.target,
        // uri: parsed.uri,
      ),
    ),
    (LinkType.spaceObject) => html.InlineCustomWidget(
      child: InlineItemPreview(roomId: roomId, uriResult: parsed),
    ),
    _ => null, // not yet supported
  };
}
