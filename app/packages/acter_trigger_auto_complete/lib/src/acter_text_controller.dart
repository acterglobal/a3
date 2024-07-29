import 'package:flutter/material.dart';

/// Extended [TextEditingController] which takes up trigger styles as optional.
/// Styles the trigger inputs based on map for mentions, hashtags or emojis etc.
/// If provided empty, will
class ActerTextController extends TextEditingController {
  ActerTextController({super.text, this.triggerStyles});

  final Map<String, TextStyle>? triggerStyles;
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<TextSpan> children = [];
    final String text = this.text;

    if (triggerStyles == null || triggerStyles!.isEmpty) {
      return TextSpan(text: text, style: style ?? const TextStyle());
    }

    int lastIndex = 0;
    for (final entry in triggerStyles!.entries) {
      final trigger = entry.key;
      final triggerStyle = entry.value;

      final regex = RegExp('\\$trigger\\S+(?: \\S+)*(?=\\s)');
      final matches = regex.allMatches(text);

      for (final match in matches) {
        if (match.start > lastIndex) {
          children.add(TextSpan(
            text: text.substring(lastIndex, match.start),
            style: style ?? const TextStyle(),
          ),);
        }
        children.add(TextSpan(
          text: match.group(0),
          style: (style ?? const TextStyle()).merge(triggerStyle),
        ),);
        lastIndex = match.end;
      }
    }

    if (lastIndex < text.length) {
      children.add(TextSpan(
        text: text.substring(lastIndex),
        style: style ?? const TextStyle(),
      ),);
    }

    return TextSpan(children: children);
  }
}
