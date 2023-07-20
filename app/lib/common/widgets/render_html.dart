import 'package:acter/common/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RenderHtml extends ConsumerWidget {
  final String text;
  final TextStyle? defaultTextStyle;
  const RenderHtml({
    super.key,
    required this.text,
    this.defaultTextStyle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Html(
      onLinkTap: (target) async {
        await openLink(target, context);
      },
      data: text,
      defaultTextStyle: defaultTextStyle,
    );
  }
}
