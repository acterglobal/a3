// import 'package:flutter/material.dart';

// /// Extended [TextEditingController] which takes up trigger styles as optional.
// /// Styles the trigger inputs based on map for mentions, hashtags or emojis etc.
// /// If provided empty, will use default [TextStyle].
// class ActerTriggerAutoCompleteTextController extends TextEditingController {
//   ActerTriggerAutoCompleteTextController({super.text, this.triggerStyles});

//   final Map<String, TextStyle>? triggerStyles;
//   @override
//   TextSpan buildTextSpan({
//     required BuildContext context,
//     TextStyle? style,
//     required bool withComposing,
//   }) {
//     final List<TextSpan> children = [];
//     final String text = this.text;

//     if (triggerStyles == null || triggerStyles!.isEmpty) {
//       return TextSpan(text: text, style: style ?? const TextStyle());
//     }

//     int lastIndex = 0;
//     for (final entry in triggerStyles!.entries) {
//       final trigger = entry.key;
//       final triggerStyle = entry.value;
//       // This regex matches a string that starts with trigger followed by one or more non-whitespace characters.
//       // It can be optionally followed by additional groups of one or more non-whitespace characters separated by spaces.
//       // The match stops at a trailing last word whitespace character.
//       /// Example: @John, @John Doe etc.
//       final regex = RegExp('\\$trigger\\S+(?: \\S+)*(?=\\s)');
//       final matches = regex.allMatches(text);

//       for (final match in matches) {
//         if (match.start > lastIndex) {
//           children.add(
//             TextSpan(
//               text: text.substring(lastIndex, match.start),
//               style: style ?? const TextStyle(),
//             ),
//           );
//         }
//         children.add(
//           TextSpan(
//             text: match.group(0),
//             style: (style ?? const TextStyle()).merge(triggerStyle),
//           ),
//         );
//         lastIndex = match.end;
//       }
//     }

//     if (lastIndex < text.length) {
//       children.add(
//         TextSpan(
//           text: text.substring(lastIndex),
//           style: style ?? const TextStyle(),
//         ),
//       );
//     }

//     return TextSpan(children: children);
//   }
// }

import 'package:flutter/material.dart';

class TaggedText {
  final String trigger;
  final String displayText;
  final int start;
  final int end;

  TaggedText({
    required this.trigger,
    required this.displayText,
    required this.start,
    required this.end,
  });
}

/// Extended [TextEditingController] which handles generic triggers.
class ActerTriggerAutoCompleteTextController extends TextEditingController {
  ActerTriggerAutoCompleteTextController({
    super.text,
    this.triggerStyles,
  }) {
    addListener(_tagListener);
  }

  @override
  void dispose() {
    removeListener(_tagListener);
    super.dispose();
  }

  final Map<String, TextStyle>? triggerStyles;
  final List<TaggedText> _tags = [];

  void addTag(TaggedText tag) {
    _tags.add(tag);
    notifyListeners();
  }

  void removeTag(TaggedText tag) {
    _tags.removeWhere((t) => t.start == tag.start && t.end == tag.end);
    notifyListeners();
  }

  void _tagListener() {
    final text = this.text;
    final selection = this.selection;

    // Check if we're at the end of a tag
    final potentialTagEnd = selection.baseOffset;
    final tagToRemove = _tags.firstWhere(
      (tag) => tag.end == potentialTagEnd,
      orElse: () =>
          TaggedText(trigger: '', displayText: '', start: -1, end: -1),
    );

    if (tagToRemove.start != -1) {
      // We're at the end of a tag, check if the user is trying to delete it
      if (selection.baseOffset != selection.extentOffset ||
          (selection.baseOffset > 0 && text[selection.baseOffset - 1] == ' ')) {
        removeTag(tagToRemove);
        // You might want to also remove the tag from the text here
        this.text = text.replaceRange(tagToRemove.start, tagToRemove.end, '');
      }
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<TextSpan> children = [];
    final String text = this.text;

    if (triggerStyles == null || triggerStyles!.isEmpty || _tags.isEmpty) {
      return TextSpan(text: text, style: style ?? const TextStyle());
    }

    int lastIndex = 0;
    for (final tag in _tags) {
      if (tag.start > lastIndex) {
        children.add(
          TextSpan(
            text: text.substring(lastIndex, tag.start),
            style: style ?? const TextStyle(),
          ),
        );
      }

      final triggerStyle = triggerStyles![tag.trigger] ?? const TextStyle();
      children.add(
        TextSpan(
          text: text.substring(tag.start, tag.end),
          style: (style ?? const TextStyle()).merge(triggerStyle),
        ),
      );

      lastIndex = tag.end;
    }

    if (lastIndex < text.length) {
      children.add(
        TextSpan(
          text: text.substring(lastIndex),
          style: style ?? const TextStyle(),
        ),
      );
    }

    return TextSpan(children: children);
  }
}
