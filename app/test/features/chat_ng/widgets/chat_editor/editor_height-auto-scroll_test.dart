import 'dart:io';

import 'package:acter/features/chat_ng/utils.dart';
import 'package:acter/common/widgets/html_editor/html_editor.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class TestableEditor extends StatefulWidget {
  const TestableEditor({super.key});

  @override
  State<TestableEditor> createState() => _TestableEditorState();
}

class _TestableEditorState extends State<TestableEditor> {
  final EditorState editorState = EditorState.blank();
  late EditorScrollController scrollController;
  final ValueNotifier<double> _contentHeightNotifier = ValueNotifier(56.0);

  @override
  void initState() {
    super.initState();
    scrollController = EditorScrollController(editorState: editorState);
  }

  @override
  void dispose() {
    _contentHeightNotifier.dispose();
    super.dispose();
  }

  void updateContentHeight(String text) {
    setState(() {
      double newHeight = ChatEditorUtils.calculateContentHeight(text);
      newHeight = newHeight.clamp(
        ChatEditorUtils.baseHeight,
        ChatEditorUtils.maxHeight,
      );
      _contentHeightNotifier.value = newHeight;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _contentHeightNotifier,
      builder: (context, height, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: MediaQuery.of(context).size.width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: HtmlEditor(
            footer: null,
            hintText: 'Test hint',
            editable: true,
            shrinkWrap: height > ChatEditorUtils.scrollThreshold,
            disableAutoScroll: !(height > ChatEditorUtils.scrollThreshold),
            editorState: editorState,
            scrollController: scrollController,
          ),
        );
      },
    );
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  final testDir = Directory.current.path;
  final goldenDir =
      '$testDir/test/features/chat_ng/widgets/chat_editor/goldens';

  goldenFileComparator = LocalFileComparator(Uri.parse(goldenDir));

  // mock the platform channels also
  const channel = MethodChannel('keyboardHeightEventChannel');
  binding.defaultBinaryMessenger.setMockMethodCallHandler(
    channel,
    (MethodCall methodCall) async => null,
  );

  group('ChatEditor Golden Tests', () {
    testWidgets('renders with default height for empty input', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 200));

      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: SizedBox(width: 400, height: 200, child: TestableEditor()),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      await expectLater(
        find.byType(TestableEditor),
        matchesGoldenFile('goldens/editor_default_height.png'),
      );

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('increases height for multiline input', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 200));

      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: SizedBox(width: 400, height: 200, child: TestableEditor()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final editorFinder = find.byType(HtmlEditor);
      expect(editorFinder, findsOneWidget);

      final editorState = tester.widget<HtmlEditor>(editorFinder).editorState;

      // multiline text
      final transaction = editorState!.transaction;
      final docNode = editorState.getNodeAtPath([0]);
      transaction.replaceText(
        docNode!,
        0,
        docNode.delta?.length ?? 0,
        'Line 1\nLine 2\nLine 3\nLine 4',
      );
      editorState.apply(transaction);

      final state = tester.state<_TestableEditorState>(
        find.byType(TestableEditor),
      );
      state.updateContentHeight('Line 1\nLine 2\nLine 3\nLine 4');

      // update height delay
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(TestableEditor),
        matchesGoldenFile('goldens/editor_multiline_height.png'),
      );

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('enables scrolling for large input', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 200));

      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: SizedBox(width: 400, height: 200, child: TestableEditor()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final editorFinder = find.byType(HtmlEditor);
      expect(editorFinder, findsOneWidget);

      final editorState = tester.widget<HtmlEditor>(editorFinder).editorState;

      // calculate how many lines would exceed scroll threshold
      final linesNeededToExceedThreshold =
          ((ChatEditorUtils.scrollThreshold - ChatEditorUtils.baseHeight) /
                  ChatEditorUtils.lineHeight)
              .ceil() +
          1;

      // create text
      final largeText = List.generate(
        linesNeededToExceedThreshold + 2, //  extra lines to ensure scrolling
        (i) => 'Line $i',
      ).join('\n');

      // insert large text
      final transaction = editorState!.transaction;
      final docNode = editorState.getNodeAtPath([0]);
      transaction.replaceText(
        docNode!,
        0,
        docNode.delta?.length ?? 0,
        largeText,
      );
      editorState.apply(transaction);

      final state = tester.state<_TestableEditorState>(
        find.byType(TestableEditor),
      );
      state.updateContentHeight(largeText);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(TestableEditor),
        matchesGoldenFile('goldens/editor_scrollable_height.png'),
      );

      // verify auto scrolling enabled
      // HtmlEditor (shrinkWrap = true)
      final htmlEditor = tester.widget<HtmlEditor>(find.byType(HtmlEditor));
      expect(htmlEditor.shrinkWrap, isTrue);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('caps height at maximum value', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 300));

      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: SizedBox(width: 400, height: 300, child: TestableEditor()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // find the editor and insert very large text
      final editorFinder = find.byType(HtmlEditor);
      expect(editorFinder, findsOneWidget);

      // get the editor state
      final editorState = tester.widget<HtmlEditor>(editorFinder).editorState;

      // calculate how many lines would exceed max height
      final linesNeededToExceedMax =
          ((ChatEditorUtils.maxHeight - ChatEditorUtils.baseHeight) /
                  ChatEditorUtils.lineHeight)
              .ceil() +
          5; // extra lines

      // create text with enough lines to exceed max height
      final veryLargeText = List.generate(
        linesNeededToExceedMax,
        (i) => 'Line $i that is very long to ensure wrapping happens',
      ).join('\n');

      // insert very large text
      final transaction = editorState!.transaction;
      final docNode = editorState.getNodeAtPath([0]);
      transaction.replaceText(
        docNode!,
        0,
        docNode.delta?.length ?? 0,
        veryLargeText,
      );
      editorState.apply(transaction);

      final state = tester.state<_TestableEditorState>(
        find.byType(TestableEditor),
      );
      state.updateContentHeight(veryLargeText);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(TestableEditor),
        matchesGoldenFile('goldens/editor_max_height.png'),
      );

      // height property should be at maximum
      expect(
        state._contentHeightNotifier.value,
        equals(ChatEditorUtils.maxHeight),
      );

      await tester.binding.setSurfaceSize(null);
    });
  });
}
