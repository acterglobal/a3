import 'package:acter/common/actions/open_link.dart';
import 'package:acter/common/toolkit/buttons/user_chip.dart';
import 'package:acter/features/chat_ng/utils.dart';
import 'package:acter/features/deep_linking/parse_acter_uri.dart';
import 'package:acter/features/deep_linking/types.dart';
import 'package:acter/features/deep_linking/widgets/inline_item_preview.dart';
import 'package:acter/features/room/widgets/room_chip.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/dom.dart' as dom;
import 'package:logging/logging.dart';

final _log = Logger('a3::toolkit::html::render_html_ng');

class MaxSizeWidgetFactory extends WidgetFactory {
  final double maxHeight;
  MaxSizeWidgetFactory({required this.maxHeight});

  @override
  Widget buildBodyWidget(BuildContext context, Widget child) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ClipRect(clipBehavior: Clip.antiAlias, child: child),
    );
  }

  @override
  Widget buildColumnWidget(
    BuildContext context,
    List<Widget> children, {
    CrossAxisAlignment? crossAxisAlignment,
    TextDirection? dir,
  }) {
    if (children.length == 1) {
      return children.first;
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.start,
      textDirection: dir,
      children: children,
    );
  }
}

final linkMatcher = RegExp(
  r'(https?:\/\/|matrix:|acter:)([^\s]+)',
  multiLine: true,
  unicode: true,
);

/// Customized [html.HtmlWidget] that:
/// - renders object links, room links, user links as pills
class RenderHtmlNg extends ConsumerWidget {
  final String html;
  final TextStyle? defaultTextStyle;
  final TextStyle? linkTextStyle;
  final bool shrinkToFit;
  final int? maxLines;
  final String? roomId;
  final Color? backgroundColor;
  const RenderHtmlNg({
    super.key,
    required this.html,
    this.defaultTextStyle,
    this.linkTextStyle,
    this.shrinkToFit = false,
    this.maxLines,
    this.roomId,
    this.backgroundColor,
  });

  /// You don't have an HTML but want us to autodetect links?
  /// provide the text and we will autodetect the links for you
  RenderHtmlNg.text({
    super.key,
    required text,
    this.defaultTextStyle,
    this.linkTextStyle,
    this.shrinkToFit = false,
    this.maxLines,
    this.roomId,
    this.backgroundColor,
  }) : html = text.replaceAllMapped(
         linkMatcher,
         (match) => '<a href="${match[0]!}">${match[2]!}</a>',
       );

  @override
  Widget build(BuildContext context, WidgetRef ref) => HtmlWidget(
    html,
    onTapUrl: (url) => openLink(ref: ref, target: url, lang: L10n.of(context)),
    textStyle: defaultTextStyle,
    renderMode: RenderMode.column,
    factoryBuilder: customWidgetFactory(context, ref),

    customWidgetBuilder:
        (dom.Element element) => customWidgetBuilder(context, ref, element),

    customStylesBuilder: // overwriting the default link color
        (element) =>
            element.localName?.toLowerCase() == 'a'
                ? _linkStylesBuilder()
                : null,
  );

  Map<String, String>? _linkStylesBuilder() {
    final linkTextStyle = this.linkTextStyle;
    if (linkTextStyle == null) {
      return null;
    }
    final styles = <String, String>{
      'color': linkTextStyle.color?.toCssString() ?? 'white',
    };
    if (linkTextStyle.decoration != TextDecoration.none) {
      styles['text-decoration-line'] = switch (linkTextStyle.decoration) {
        TextDecoration.underline => 'underline',
        TextDecoration.lineThrough => 'line-through',
        TextDecoration.overline => 'overline',
        _ => 'none',
      };
    }
    return styles;
  }

  WidgetFactory Function()? customWidgetFactory(
    BuildContext context,
    WidgetRef ref,
  ) {
    final mxLines = maxLines;
    if (mxLines == null) {
      return null;
    }

    final fontSize =
        (defaultTextStyle?.fontSize ??
            Theme.of(context).textTheme.bodyMedium?.fontSize ??
            12);
    final lineHeight =
        (defaultTextStyle?.height ??
            Theme.of(context).textTheme.bodyMedium?.height ??
            1);
    final maxHeight = (mxLines * fontSize * lineHeight).toDouble();
    return () => MaxSizeWidgetFactory(maxHeight: maxHeight);
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
      return _buildPill(parsed, uri);
      // } else {
      //   // if the link title has been changed
      //   // we should show the original link
      //   return null;
      // }
    } on UriParseError catch (error, stackTrace) {
      _log.warning('failed to parse acter uri', error, stackTrace);
      return null;
    }
  }

  Widget? _buildPill(UriParseResult parsed, Uri uri) => switch (parsed.type) {
    (LinkType.userId) => InlineCustomWidget(
      child: UserChip(
        roomId: roomId,
        memberId: parsed.target,
        style: defaultTextStyle,
      ),
    ),
    (LinkType.roomId) => InlineCustomWidget(
      child: RoomChip(roomId: parsed.target, uri: uri),
    ),
    (LinkType.spaceObject) => InlineCustomWidget(
      child: InlineItemPreview(roomId: roomId, uriResult: parsed),
    ),
    _ => null, // not yet supported
  };
}
