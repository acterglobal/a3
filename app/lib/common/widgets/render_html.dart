import 'package:acter/common/actions/open_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef PillBuilder = Widget Function({
  required String identifier,
  required String url,
  void Function(String)? onTap,
});

class RenderHtml extends ConsumerWidget {
  final String text;
  final TextStyle? defaultTextStyle;
  final TextStyle? linkTextStyle;
  final bool shrinkToFit;
  final int? maxLines;
  final bool renderNewlines;
  final PillBuilder? pillBuilder;
  const RenderHtml({
    super.key,
    required this.text,
    this.defaultTextStyle,
    this.linkTextStyle,
    this.shrinkToFit = false,
    this.maxLines,
    this.renderNewlines = false,
    this.pillBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Html(
      onLinkTap: (target) async {
        await openLink(ref, target.toString(), context);
      },
      maxLines: maxLines,
      shrinkToFit: shrinkToFit,
      renderNewlines: renderNewlines,
      data: text,
      pillBuilder: pillBuilder,
      defaultTextStyle: defaultTextStyle,
      linkStyle: linkTextStyle,
    );
  }
}
