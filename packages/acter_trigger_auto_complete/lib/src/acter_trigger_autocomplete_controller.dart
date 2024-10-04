import 'package:flutter/material.dart';

// Tags Representation .i.e. user mentions, room mentions etc
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

/// /// Extended [TextEditingController] which takes up trigger styles as optional.
/// Styles the trigger inputs based on map for mentions, hashtags or emojis etc.
/// If provided empty, will use default [TextStyle].
class ActerTriggerAutoCompleteTextController extends TextEditingController {
  ActerTriggerAutoCompleteTextController({
    super.text,
    this.triggerStyles,
  }) {
    // add listener for tag changes
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

  void _updateTagPositions() {
    final text = this.text;
    _tags.removeWhere((tag) => tag.start >= text.length);

    for (var i = 0; i < _tags.length; i++) {
      var tag = _tags[i];
      if (tag.end > text.length) {
        tag = TaggedText(
          trigger: tag.trigger,
          displayText: text.substring(tag.start, text.length),
          start: tag.start,
          end: text.length,
        );
        _tags[i] = tag;
      }
    }
  }

  void _tagListener() {
    _updateTagPositions();

    final text = this.text;
    final selection = this.selection;

    // Check if we're at the end of a tag or just after it
    final potentialTagEnd = selection.baseOffset;
    final tagToRemove = _tags.firstWhere(
      (tag) => tag.end == potentialTagEnd || tag.end == potentialTagEnd + 1,
      orElse: () =>
          TaggedText(trigger: '', displayText: '', start: -1, end: -1),
    );

    if (tagToRemove.start != -1) {
      // Check if the user is actually trying to delete the tag
      if (selection.baseOffset == selection.extentOffset &&
          selection.baseOffset > 0 &&
          text.length < value.composing.start) {
        // Check if text was actually deleted

        // Remove the entire tag
        removeTag(tagToRemove);

        // Remove the tag from the text
        value = TextEditingValue(
          text: text.replaceRange(tagToRemove.start, tagToRemove.end, ''),
          selection: TextSelection.collapsed(offset: tagToRemove.start),
        );
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
