import 'package:acter/features/chat_ng/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Chat Editor Utils - unit tests', () {
    group('calculate content height group tests', () {
      test('returns base height for empty text', () {
        expect(
          ChatEditorUtils.calculateContentHeight(''),
          ChatEditorUtils.baseHeight,
        );
      });

      test('returns base height for single line text', () {
        expect(
          ChatEditorUtils.calculateContentHeight('Single line text'),
          ChatEditorUtils.baseHeight,
        );
      });

      test('increases height for multiline text', () {
        expect(
          ChatEditorUtils.calculateContentHeight('Line 1\nLine 2'),
          ChatEditorUtils.baseHeight,
        );

        expect(
          ChatEditorUtils.calculateContentHeight('Line 1\nLine 2\nLine 3'),
          ChatEditorUtils.baseHeight + 2 * ChatEditorUtils.lineHeight,
        );
      });

      test('caps height at maximum allowed value', () {
        // calculate how many lines would exceed max height
        final linesNeededToExceedMax =
            ((ChatEditorUtils.maxHeight - ChatEditorUtils.baseHeight) /
                    ChatEditorUtils.lineHeight)
                .ceil();

        // create text with enough newlines to exceed max height
        final largeText = List.generate(
          linesNeededToExceedMax + 1,
          (i) => 'Line $i',
        ).join('\n');

        expect(
          ChatEditorUtils.calculateContentHeight(largeText),
          ChatEditorUtils.maxHeight,
        );
      });
    });

    group('should enable scrolling group tests', () {
      test('returns false for height at or below threshold', () {
        expect(
          ChatEditorUtils.shouldEnableScrolling(ChatEditorUtils.baseHeight),
          false,
        );
        expect(
          ChatEditorUtils.shouldEnableScrolling(
            ChatEditorUtils.scrollThreshold,
          ),
          false,
        );
      });

      test('returns true for height above threshold', () {
        expect(
          ChatEditorUtils.shouldEnableScrolling(
            ChatEditorUtils.scrollThreshold + 0.1,
          ),
          true,
        );
        expect(
          ChatEditorUtils.shouldEnableScrolling(ChatEditorUtils.maxHeight),
          true,
        );
      });

      test('calculates correctly for different line counts', () {
        // two lines (one newline) gives base height (56), which is below threshold
        final heightForTwoLines = ChatEditorUtils.calculateContentHeight(
          'Line 1\nLine 2',
        );

        // three lines (two newlines) gives base height + 2*lineHeight = 56 + 40 = 96,
        // which equals the threshold of 96
        final heightForThreeLines = ChatEditorUtils.calculateContentHeight(
          'Line 1\nLine 2\nLine 3',
        );

        // four lines (three newlines) gives base height + 3*lineHeight = 56 + 60 = 116,
        // which is above the threshold of 96
        final heightForFourLines = ChatEditorUtils.calculateContentHeight(
          'Line 1\nLine 2\nLine 3\nLine 4',
        );

        expect(ChatEditorUtils.shouldEnableScrolling(heightForTwoLines), false);
        expect(
          ChatEditorUtils.shouldEnableScrolling(heightForThreeLines),
          false,
        );
        expect(ChatEditorUtils.shouldEnableScrolling(heightForFourLines), true);
      });
    });
  });
}
