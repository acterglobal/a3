import 'package:acter/common/toolkit/widgets/acter_selection_area.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ActerSelectionArea widget tests', () {
    final selectedText = ValueNotifier<String?>(null);

    setUp(() {
      selectedText.value = null;

      // set up clipboard channel mock to capture and verify text selection
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.textInput, (
            MethodCall methodCall,
          ) async {
            if (methodCall.method == 'TextInput.setEditingState') {
              final Map<String, dynamic> args = methodCall.arguments;
              if (args.containsKey('text')) {
                selectedText.value = args['text'];
              }
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.textInput, null);
    });

    testWidgets('should allow text selection and copy', (
      WidgetTester tester,
    ) async {
      const testText = 'This is selectable text';
      String? clipboardContent;

      // setup clipboard capture
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (
            MethodCall methodCall,
          ) async {
            if (methodCall.method == 'Clipboard.setData') {
              final Map<String, dynamic> args = methodCall.arguments;
              clipboardContent = args['text'];
              return null;
            }
            if (methodCall.method == 'Clipboard.getData') {
              return {'text': clipboardContent};
            }
            return null;
          });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ActerSelectionArea(child: Text(testText)),
            ),
          ),
        ),
      );

      final textFinder = find.text(testText);
      expect(textFinder, findsOneWidget);

      await tester.pumpAndSettle();

      // select text by simulating a long press and drag
      await tester.longPress(textFinder);
      await tester.pump();
      await tester.dragFrom(
        tester.getTopLeft(textFinder),
        Offset(testText.length * 10.0, 0),
      );
      await tester.pump();

      await tester.pumpAndSettle();

      // show context menu and select copy
      await tester.longPress(textFinder);
      await tester.pumpAndSettle();

      // find and tap the copy option
      final copyFinder = find.text('Copy');
      expect(copyFinder, findsOneWidget);
      await tester.tap(copyFinder);
      await tester.pumpAndSettle();

      // verify clipboard content
      expect(
        clipboardContent,
        isNotNull,
        reason: 'Clipboard content should not be null',
      );
      expect(
        clipboardContent,
        contains('selectable'),
        reason: 'The clipboard should contain part of the selected text',
      );

      // reset mock
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('nested text should be selectable and copyable', (
      WidgetTester tester,
    ) async {
      String? clipboardContent;

      // setup clipboard capture
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (
            MethodCall methodCall,
          ) async {
            if (methodCall.method == 'Clipboard.setData') {
              final Map<String, dynamic> args = methodCall.arguments;
              clipboardContent = args['text'];
              return null;
            }
            if (methodCall.method == 'Clipboard.getData') {
              return {'text': clipboardContent};
            }
            return null;
          });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActerSelectionArea(
              child: Column(
                children: [
                  Text('Text 1'),
                  Container(
                    padding: EdgeInsets.all(8),
                    child: Text('Nested text'),
                  ),
                  Text('Text 3'),
                ],
              ),
            ),
          ),
        ),
      );

      final textFinder = find.text('Nested text');
      expect(textFinder, findsOneWidget);

      await tester.pumpAndSettle();

      // verify SelectionArea exists
      final selectionAreaFinder = find.byType(SelectionArea);
      expect(selectionAreaFinder, findsOneWidget);

      // select text by simulating a long press and drag
      await tester.longPress(textFinder);
      await tester.pump();
      await tester.dragFrom(
        tester.getTopLeft(textFinder),
        Offset('Nested text'.length * 10.0, 0),
      );
      await tester.pump();

      // wait for selection to be applied
      await tester.pumpAndSettle();

      // show context menu and select copy
      await tester.longPress(textFinder);
      await tester.pumpAndSettle();

      // find and tap the copy option
      final copyFinder = find.text('Copy');
      expect(copyFinder, findsOneWidget);
      await tester.tap(copyFinder);
      await tester.pumpAndSettle();

      // verify clipboard content
      expect(
        clipboardContent,
        isNotNull,
        reason: 'Clipboard content should not be null',
      );
      expect(
        clipboardContent,
        contains('Nested'),
        reason: 'The clipboard should contain part of the selected text',
      );

      // reset mock
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
  });
}
