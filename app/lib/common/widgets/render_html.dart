import 'package:acter/common/actions/open_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RenderHtml extends ConsumerWidget {
  final String text;
  final TextStyle? defaultTextStyle;
  final TextStyle? linkTextStyle;
  const RenderHtml({
    super.key,
    required this.text,
    this.defaultTextStyle,
    this.linkTextStyle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Html(
      onLinkTap: (target) async {
        await openLink(ref, target.toString(), context);
      },
      data: text,
      defaultTextStyle: defaultTextStyle,
      linkStyle: linkTextStyle,
    );
  }
}
