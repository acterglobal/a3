import 'package:acter/common/actions/open_link.dart';
import 'package:acter/common/toolkit/buttons/user_chip.dart';
import 'package:acter/features/chat_ng/utils.dart';
import 'package:acter/features/deep_linking/parse_acter_uri.dart';
import 'package:acter/features/deep_linking/types.dart';
import 'package:acter/features/deep_linking/widgets/inline_item_preview.dart';
import 'package:acter/features/room/widgets/room_chip.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/solarized-dark.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/dom.dart' as dom;
import 'package:highlight/highlight.dart' show highlight;
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

class CodeBlockWidget extends StatefulWidget {
  final String code;
  final String? language;
  const CodeBlockWidget({super.key, required this.code, this.language});

  @override
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<CodeBlockWidget> {
  String? language;
  final _verticalScrollController = ScrollController();
  final _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    language = widget.language;
    autodetectLanguage();
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CodeBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) {
      language = widget.language;
      autodetectLanguage();
    }
  }

  void autodetectLanguage() {
    if (language != null) {
      return; // a language was provided
    }
    final someCode =
        widget.code.length > 250 ? widget.code.substring(0, 250) : widget.code;
    final detected = highlight.parse(someCode, autoDetection: true);
    setState(() {
      language = detected.language;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(9.5)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 250),
          child: Scrollbar(
            thumbVisibility: true,
            controller: _verticalScrollController,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              controller: _verticalScrollController,
              child: Scrollbar(
                thumbVisibility: true,
                controller: _horizontalScrollController,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _horizontalScrollController,
                  child: HighlightView(
                    widget.code,
                    language: language ?? 'plain', // fallback to plain text
                    theme: solarizedDarkTheme,
                    tabSize: 2,
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 10.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
  }) : html = text
           .replaceAllMapped(
             linkMatcher,
             // we replace links we've found with an html version for the inner
             // rendering engine
             (match) => '<a href="${match[0]!}">${match[2]!}</a>',
           )
           .replaceAll('\n', '<br>');

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
    'code' => _handleCodeBlock(context, ref, element),
    _ => null,
  };

  Widget? _handleCodeBlock(
    BuildContext context,
    WidgetRef ref,
    dom.Element element,
  ) {
    final parentTag = element.parent?.localName?.toLowerCase();
    if (parentTag != 'pre') {
      return null;
    }

    // looking for the language class if supplied
    final language = element.classes
        .cast<String?>()
        .firstWhere(
          (s) => s?.startsWith('language-') ?? false,
          orElse: () => null,
        )
        ?.substring('language-'.length);
    return CodeBlockWidget(code: element.text, language: language);
  }

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
