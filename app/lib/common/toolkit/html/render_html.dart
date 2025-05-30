import 'package:acter/common/actions/open_link.dart';
import 'package:acter/common/toolkit/html/render_html_ng.dart';
import 'package:acter/features/chat/widgets/pill_builder.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_matrix_html/flutter_html.dart' as matrix_html;
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
  final PillBuilder? pillBuilder;
  final Color? backgroundColor;
  const _MatrixRenderHtml({
    required this.text,
    this.defaultTextStyle,
    this.linkTextStyle,
    this.shrinkToFit = false,
    this.maxLines,
    this.pillBuilder,
    this.backgroundColor,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return matrix_html.Html(
      onLinkTap: (target) async {
        await openLink(
          ref: ref,
          target: target.toString(),
          lang: L10n.of(context),
        );
      },
      maxLines: maxLines,
      shrinkToFit: shrinkToFit,
      data: text,
      pillBuilder: pillBuilder,
      defaultTextStyle: defaultTextStyle,
      linkStyle: linkTextStyle,
      backgroundColor: backgroundColor,
    );
  }
}

class RenderHtml extends ConsumerWidget {
  final String text;
  final TextStyle? defaultTextStyle;
  final TextStyle? linkTextStyle;
  final bool shrinkToFit;
  final int? maxLines;
  final String? roomId;
  final Color backgroundColor;
  const RenderHtml({
    super.key,
    required this.text,
    this.defaultTextStyle,
    this.linkTextStyle,
    this.shrinkToFit = false,
    this.maxLines,
    this.roomId,
    this.backgroundColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextHtml = ref.watch(isActiveProvider(LabsFeature.htmlNext));
    final linkStyle =
        linkTextStyle ??
        TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          decoration: TextDecoration.underline,
        );
    if (nextHtml) {
      return RenderHtmlNg(
        text: text,
        defaultTextStyle: defaultTextStyle,
        linkTextStyle: linkStyle,
        shrinkToFit: shrinkToFit,
        maxLines: maxLines,
        roomId: roomId,
        backgroundColor: backgroundColor,
      );
    } else {
      return _MatrixRenderHtml(
        text: text,
        defaultTextStyle: defaultTextStyle,
        linkTextStyle: linkStyle,
        shrinkToFit: shrinkToFit,
        maxLines: maxLines,
        backgroundColor: backgroundColor,
        pillBuilder:
            ({
              required String identifier,
              required String url,
              void Function(String)? onTap,
            }) => ActerPillBuilder(
              identifier: identifier,
              uri: url,
              roomId: roomId,
            ),
      );
    }
  }
}
