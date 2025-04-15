import 'package:flutter/material.dart';

class TextMessageWidget extends StatelessWidget {
  final String? senderName;
  final String? message;
  final bool isDM;
  final TextStyle? textStyle;

  const TextMessageWidget({
    super.key,
    this.senderName,
    this.message,
    this.isDM = false,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final bodySmallTextStyle = Theme.of(context).textTheme.bodySmall;
    final effectiveStyle = textStyle ?? bodySmallTextStyle;

    final List<InlineSpan> spans = [];
    if (senderName != null && !isDM) {
      spans.add(TextSpan(text: '$senderName : ', style: effectiveStyle));
    }
    spans.add(TextSpan(text: message ?? '', style: effectiveStyle));

    return RichText(text: TextSpan(children: spans, style: effectiveStyle));
  }
}
