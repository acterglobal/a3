// import 'package:acter/features/chat_ng/utils.dart';
// import 'package:flutter_test/flutter_test.dart';

// void main() {
//   group('Chat Editor Utils - unit tests', () {
//     group('calculate content height group tests', () {
//       test('returns base height for empty text', () {
//         expect(
//           ChatEditorUtils.calculateContentHeight(''),
//           ChatEditorUtils.baseHeight,
//         );
//       });

//       test('returns base height for single line text', () {
//         expect(
//           ChatEditorUtils.calculateContentHeight('Single line text'),
//           ChatEditorUtils.baseHeight,
//         );
//       });

//       test('increases height for multiline text', () {
//         expect(
//           ChatEditorUtils.calculateContentHeight('Line 1\nLine 2'),
//           ChatEditorUtils.baseHeight,
//         );

//         expect(
//           ChatEditorUtils.calculateContentHeight('Line 1\nLine 2\nLine 3'),
//           ChatEditorUtils.baseHeight + 2 * ChatEditorUtils.lineHeight,
//         );
//       });

//       test('caps height at maximum allowed value', () {
//         // calculate how many lines would exceed max height
//         final linesNeededToExceedMax =
//             ((ChatEditorUtils.maxHeight - ChatEditorUtils.baseHeight) /
//                     ChatEditorUtils.lineHeight)
//                 .ceil();

//         // create text with enough newlines to exceed max height
//         final largeText = List.generate(
//           linesNeededToExceedMax + 1,
//           (i) => 'Line $i',
//         ).join('\n');

//         expect(
//           ChatEditorUtils.calculateContentHeight(largeText),
//           ChatEditorUtils.maxHeight,
//         );
//       });
//     });
//   });
// }
