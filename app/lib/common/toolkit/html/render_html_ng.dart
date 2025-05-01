import 'package:acter/common/actions/open_link.dart';
import 'package:acter/common/toolkit/buttons/user_chip.dart';
import 'package:acter/features/deep_linking/parse_acter_uri.dart';
import 'package:acter/features/deep_linking/types.dart';
import 'package:acter/features/deep_linking/widgets/inline_item_preview.dart';
import 'package:acter/features/room/widgets/room_chip.dart';
import 'package:acter/l10n/generated/l10n.dart';
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
    final htmlWidget = html.HtmlWidget(
      text,
      onTapUrl:
          (url) => openLink(ref: ref, target: url, lang: L10n.of(context)),
      textStyle: defaultTextStyle,
      customWidgetBuilder:
          (dom.Element element) => customWidgetBuilder(context, ref, element),
    );
    if (maxLines != null) {
      final height =
          maxLines! *
          (defaultTextStyle?.fontSize ??
              Theme.of(context).textTheme.bodyMedium?.fontSize ??
              12);
      return SizedBox(
        height: height.toDouble(),
        child: ClipRect(child: htmlWidget),
      );
    }
    return htmlWidget;
  }

  Widget? customWidgetBuilder(
    BuildContext context,
    WidgetRef ref,
    dom.Element element,
  ) => switch (element.localName?.toLowerCase()) {
    'a' => _handleLink(context, ref, element),
    _ => null,
  };

  Widget? _handleLink(
    BuildContext context,
    WidgetRef ref,
    dom.Element element,
  ) {
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
      // FIXME: what to do if the link title is different?
      // if (parsed.titleMatches(element.text)) {
      return _buildPill(parsed);
      // } else {
      //   // if the link title has been changed
      //   // we should show the original link
      //   return null;
      // }
    } on (
      SchemeNotSupported,
      IncorrectHashError,
      MissingUserError,
      ObjectNotSupported,
      ParsingFailed,
    ) {
      return null;
    }
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
