import 'package:acter/common/actions/open_link.dart';
import 'package:acter/common/toolkit/html/render_html_ng.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_matrix_html/flutter_html.dart' as matrixHtml;
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef PillBuilder =
    Widget Function({
      required String identifier,
      required String url,
      void Function(String)? onTap,
    });

class _MatrixRenderHtml extends ConsumerWidget {
  final String text;
  final TextStyle? defaultTextStyle;
  final TextStyle? linkTextStyle;
  final bool shrinkToFit;
  final int? maxLines;
  final bool renderNewlines;
  final PillBuilder? pillBuilder;
  const _MatrixRenderHtml({
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
    return matrixHtml.Html(
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

class RenderHtml extends ConsumerWidget {
  final String text;
  final TextStyle? defaultTextStyle;
  final TextStyle? linkTextStyle;
  final bool shrinkToFit;
  final int? maxLines;
  final bool renderNewlines;
  final PillBuilder? pillBuilder;
  final String roomId;
  const RenderHtml({
    super.key,
    required this.text,
    this.defaultTextStyle,
    this.linkTextStyle,
    this.shrinkToFit = false,
    this.maxLines,
    this.renderNewlines = false,
    this.pillBuilder,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextHtml = ref.watch(isActiveProvider(LabsFeature.htmlNext));
    if (nextHtml) {
      return RenderHtmlNg(
        text: text,
        defaultTextStyle: defaultTextStyle,
        linkTextStyle: linkTextStyle,
        shrinkToFit: shrinkToFit,
        maxLines: maxLines,
        renderNewlines: renderNewlines,
        roomId: roomId,
      );
    } else {
      return _MatrixRenderHtml(
        text: text,
        defaultTextStyle: defaultTextStyle,
        linkTextStyle: linkTextStyle,
        shrinkToFit: shrinkToFit,
        maxLines: maxLines,
        renderNewlines: renderNewlines,
        pillBuilder: pillBuilder,
      );
    }
  }
}
