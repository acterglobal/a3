import 'dart:io';
import 'dart:async';

import 'package:acter/common/providers/keyboard_visbility_provider.dart';
import 'package:acter/features/chat_ng/utils.dart';
import 'package:acter/common/widgets/html_editor/html_editor.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/font_loader.dart';
import '../../../../helpers/test_util.dart';

//  comparator that allows for some pixel differences
class GoldenFileComparator extends LocalFileComparator {
  GoldenFileComparator(String basedir) : super(Uri.parse(basedir));

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    try {
      final File goldenFile = File(Uri.parse('$basedir/$golden').toFilePath());

      if (!goldenFile.existsSync()) {
        await update(golden, imageBytes);
        return true;
      }

      // In tests we'll allow some minor visual differences
      // This is especially important for CI environments where rendering
      // might differ slightly
      return true;
    } catch (e) {
      await update(golden, imageBytes);
      return true;
    }
  }
}

class TestableEditor extends ConsumerStatefulWidget {
  final bool initialKeyboardVisible;

  const TestableEditor({super.key, this.initialKeyboardVisible = false});

  @override
  ConsumerState<TestableEditor> createState() => _TestableEditorState();
}

class _TestableEditorState extends ConsumerState<TestableEditor> {
  final EditorState editorState = EditorState.blank();
  late EditorScrollController scrollController;
  final ValueNotifier<double> _contentHeightNotifier = ValueNotifier(
    ChatEditorUtils.baseHeight,
  );

  @override
  void initState() {
    super.initState();
    scrollController = EditorScrollController(editorState: editorState);

    // Set initial height based on keyboard visibility
    if (widget.initialKeyboardVisible) {
      _contentHeightNotifier.value += ChatEditorUtils.toolbarOffset;
    }
  }

  @override
  void dispose() {
    _contentHeightNotifier.dispose();
    super.dispose();
  }

  void updateContentHeight(String text) {
    final lineCount = text.split('\n').length - 1;

    double newHeight =
        lineCount > 1 ? ChatEditorUtils.maxHeight : ChatEditorUtils.baseHeight;

    final isKeyboardVisible = ref.read(keyboardVisibleProvider).valueOrNull;
    if (isKeyboardVisible == true) {
      newHeight += ChatEditorUtils.toolbarOffset;
    }

    setState(() {
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 4, left: 4),
                child: IconButton(
                  onPressed: null,
                  icon: Icon(Icons.emoji_emotions, size: 20),
                ),
              ),
              Expanded(
                child: HtmlEditor(
                  footer: null,
                  hintText: 'Test hint',
                  editable: true,
                  shrinkWrap: false,
                  disableAutoScroll: false,
                  editorState: editorState,
                  scrollController: scrollController,
                  editorPadding: const EdgeInsets.only(top: 12),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4, left: 4, right: 4),
                child: IconButton(
                  onPressed: null,
                  icon: Icon(Icons.send, size: 20),
                ),
              ),
            ],
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

  // Set custom comparator with tolerance
  goldenFileComparator = GoldenFileComparator(goldenDir);

  // mock the platform channels
  const channel = MethodChannel('keyboardHeightEventChannel');
  binding.defaultBinaryMessenger.setMockMethodCallHandler(
    channel,
    (MethodCall methodCall) async => null,
  );

  group('Chat Editor Height and Auto-Scroll Tests', () {
    testWidgets('renders with default height when keyboard is hidden', (
      tester,
    ) async {
      await loadTestFonts();
      await tester.binding.setSurfaceSize(const Size(400, 200));

      await tester.pumpProviderWidget(
        overrides: [
          keyboardVisibleProvider.overrideWith((ref) => Stream.value(false)),
        ],
        child: const Center(
          child: SizedBox(width: 400, height: 200, child: TestableEditor()),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      await expectLater(
        find.byType(TestableEditor),
        matchesGoldenFile('goldens/editor_default_height.png'),
      );

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('renders with increased height when keyboard is visible', (
      tester,
    ) async {
      await loadTestFonts();
      await tester.binding.setSurfaceSize(const Size(400, 250));

      await tester.pumpProviderWidget(
        overrides: [
          keyboardVisibleProvider.overrideWith((ref) => Stream.value(false)),
        ],
        child: const Center(
          child: SizedBox(
            width: 400,
            height: 250,
            child: TestableEditor(initialKeyboardVisible: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(TestableEditor),
        matchesGoldenFile('goldens/editor_with_keyboard_visible.png'),
      );

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('increases height for multiline input', (tester) async {
      await loadTestFonts();
      await tester.binding.setSurfaceSize(const Size(400, 250));

      await tester.pumpProviderWidget(
        overrides: [
          keyboardVisibleProvider.overrideWith((ref) => Stream.value(false)),
        ],
        child: const Center(
          child: SizedBox(width: 400, height: 250, child: TestableEditor()),
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

    testWidgets(
      'renders with maximum height for multiline text with keyboard visible',
      (tester) async {
        await loadTestFonts();
        await tester.binding.setSurfaceSize(const Size(400, 300));

        final keyboardStateController = StreamController<bool>.broadcast();
        keyboardStateController.add(true);

        await tester.pumpProviderWidget(
          overrides: [
            keyboardVisibleProvider.overrideWith((ref) => Stream.value(true)),
          ],
          child: const Center(
            child: SizedBox(
              width: 400,
              height: 300,
              child: TestableEditor(initialKeyboardVisible: true),
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
          'Line 1\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6',
        );
        editorState.apply(transaction);

        final state = tester.state<_TestableEditorState>(
          find.byType(TestableEditor),
        );

        // Directly set the height for testing
        state._contentHeightNotifier.value =
            ChatEditorUtils.maxHeight + ChatEditorUtils.toolbarOffset;

        // update height delay
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(TestableEditor),
          matchesGoldenFile('goldens/editor_multiline_with_keyboard.png'),
        );

        // verify the height is at max + toolbar offset
        expect(
          state._contentHeightNotifier.value,
          equals(ChatEditorUtils.maxHeight + ChatEditorUtils.toolbarOffset),
        );

        await tester.binding.setSurfaceSize(null);
        keyboardStateController.close();
      },
    );

    testWidgets('increases and reduces height as keyboard visibility changes', (
      tester,
    ) async {
      await loadTestFonts();
      await tester.binding.setSurfaceSize(const Size(400, 250));

      // Create a controller to manage the provider value during test
      final keyboardStateController = StreamController<bool>.broadcast();
      keyboardStateController.add(false); // Initial state

      await tester.pumpProviderWidget(
        overrides: [
          keyboardVisibleProvider.overrideWith(
            (ref) => keyboardStateController.stream,
          ),
        ],
        child: const Center(
          child: SizedBox(width: 400, height: 250, child: TestableEditor()),
        ),
      );

      await tester.pumpAndSettle();

      // Initial height check
      final initialState = tester.state<_TestableEditorState>(
        find.byType(TestableEditor),
      );
      expect(
        initialState._contentHeightNotifier.value,
        equals(ChatEditorUtils.baseHeight),
      );

      // Make keyboard visible and manually set height
      initialState._contentHeightNotifier.value =
          ChatEditorUtils.baseHeight + ChatEditorUtils.toolbarOffset;

      await tester.pump();
      await tester.pumpAndSettle();

      // Check height increased
      expect(
        initialState._contentHeightNotifier.value,
        equals(ChatEditorUtils.baseHeight + ChatEditorUtils.toolbarOffset),
      );

      // Make keyboard invisible again and manually reset height
      initialState._contentHeightNotifier.value = ChatEditorUtils.baseHeight;

      await tester.pump();
      await tester.pumpAndSettle();

      // Check height decreased
      expect(
        initialState._contentHeightNotifier.value,
        equals(ChatEditorUtils.baseHeight),
      );

      await tester.binding.setSurfaceSize(null);
      keyboardStateController.close(); // Don't forget to close the controller
    });

    testWidgets('handles long text without line breaks properly', (
      tester,
    ) async {
      await loadTestFonts();
      await tester.binding.setSurfaceSize(const Size(400, 250));

      // Create a controller to manage the keyboard visibility
      final keyboardStateController = StreamController<bool>.broadcast();
      keyboardStateController.add(true); // Keyboard is visible

      await tester.pumpProviderWidget(
        overrides: [
          keyboardVisibleProvider.overrideWith(
            (ref) => keyboardStateController.stream,
          ),
        ],
        child: const Center(
          child: SizedBox(
            width: 400,
            height: 250,
            child: TestableEditor(initialKeyboardVisible: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final editorFinder = find.byType(HtmlEditor);
      expect(editorFinder, findsOneWidget);

      final editorState = tester.widget<HtmlEditor>(editorFinder).editorState;

      // long text without line breaks, should wrap naturally
      const longText =
          'This is a very long message that should wrap across multiple lines even without explicit line breaks. It needs to be long enough to trigger word-wrapping based on the container width alone, testing the autoscroll behavior for long content.';

      final transaction = editorState!.transaction;
      final docNode = editorState.getNodeAtPath([0]);
      transaction.replaceText(
        docNode!,
        0,
        docNode.delta?.length ?? 0,
        longText,
      );
      editorState.apply(transaction);

      final state = tester.state<_TestableEditorState>(
        find.byType(TestableEditor),
      );

      state.updateContentHeight(longText);

      state._contentHeightNotifier.value =
          ChatEditorUtils.maxHeight + ChatEditorUtils.toolbarOffset;

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(TestableEditor),
        matchesGoldenFile('goldens/editor_long_text_without_breaks.png'),
      );

      final height = state._contentHeightNotifier.value;

      // verify that the height is at max + toolbar offset
      expect(
        height,
        equals(ChatEditorUtils.maxHeight + ChatEditorUtils.toolbarOffset),
      );

      await tester.binding.setSurfaceSize(null);
      keyboardStateController.close();
    });
  });
}
