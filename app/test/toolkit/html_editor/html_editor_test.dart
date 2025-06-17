import 'package:acter/common/toolkit/html_editor/html_editor.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HtmlEditor Widget Tests', () {
    testWidgets('renders empty editor correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HtmlEditor(editable: true, hintText: 'Enter text here'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AppFlowyEditor), findsOneWidget);

      // Get editor state and verify content
      final editor = tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor));
      final editorState = editor.editorState;
      expect(editorState.document.root.children.length, 1);
      expect(editorState.document.root.children.first.delta?.toPlainText(), '');

      // Verify placeholder text through ParagraphBlockComponentBuilder
      final blockComponentBuilders = editor.blockComponentBuilders;
      final paragraphBuilder =
          blockComponentBuilders[ParagraphBlockKeys.type]
              as ParagraphBlockComponentBuilder;
      final configuration = paragraphBuilder.configuration;
      expect(
        configuration.placeholderText(editorState.document.root.children.first),
        'Enter text here',
      );
    });

    testWidgets('renders with initial content', (tester) async {
      final initialContent = 'Initial test content';
      final document =
          Document.blank()..insert([0], [paragraphNode(text: initialContent)]);
      final editorState = EditorState(document: document);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HtmlEditor(editable: true, editorState: editorState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Get editor state and verify content
      final editor = tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor));
      final actualEditorState = editor.editorState;
      expect(actualEditorState.document.root.children.length, 1);
      expect(
        actualEditorState.document.root.children.first.delta?.toPlainText(),
        initialContent,
      );
    });

    testWidgets('shows save and cancel buttons when callbacks provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HtmlEditor(
              editable: true,
              onSave: (_, __) {},
              onCancel: () {},
            ),
          ),
        ),
      );

      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('triggers onSave callback when save button pressed', (
      tester,
    ) async {
      String? savedText;
      String? savedHtml;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HtmlEditor(
              editable: true,
              onSave: (text, html) {
                savedText = text;
                savedHtml = html;
              },
            ),
          ),
        ),
      );

      final saveButton = find.byKey(HtmlEditor.saveEditKey);
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pump();

      expect(savedText, isNotNull);
      expect(savedHtml, isNotNull);
    });

    testWidgets('triggers onCancel callback when cancel button pressed', (
      tester,
    ) async {
      bool cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HtmlEditor(
              editable: true,
              onCancel: () {
                cancelCalled = true;
              },
            ),
          ),
        ),
      );

      final cancelButton = find.byKey(HtmlEditor.cancelEditKey);
      expect(cancelButton, findsOneWidget);
      await tester.tap(cancelButton);
      await tester.pump();

      expect(cancelCalled, isTrue);
    });

    testWidgets('renders with header and footer widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HtmlEditor(
              editable: true,
              header: const Text('Header'),
              footer: const Text('Custom Footer'),
            ),
          ),
        ),
      );

      expect(find.text('Header'), findsOneWidget);
      expect(find.text('Custom Footer'), findsOneWidget);
    });

    testWidgets('renders with HTML content', (tester) async {
      final htmlContent = '<p>Hello <strong>World</strong></p>';
      final editorState = ActerEditorStateHelpers.fromContent(
        'Baaaaahhhh',
        htmlContent,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HtmlEditor(editable: true, editorState: editorState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Get editor state and verify content
      final editor = tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor));
      final actualEditorState = editor.editorState;
      expect(actualEditorState.document.root.children.length, 1);
      expect(
        actualEditorState.document.root.children.first.delta?.toPlainText(),
        'Hello World',
      );
    });

    testWidgets('renders update of HTML content', (tester) async {
      final htmlContent = '<p>Hello <strong>World</strong></p>';
      final editorState = ActerEditorStateHelpers.fromContent(
        'Baaaaahhhh',
        null,
      );
      // started with an non-html-version
      editorState.replaceContent(
        'Bleeehhh', // stil; bad
        htmlContent,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HtmlEditor(editable: true, editorState: editorState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Get editor state and verify content
      final editor = tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor));
      final actualEditorState = editor.editorState;
      expect(actualEditorState.document.root.children.length, 1);
      expect(
        actualEditorState.document.root.children.first.delta?.toPlainText(),
        'Hello World',
      );
    });

    testWidgets('updates content height when text changes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HtmlEditor(editable: true, minHeight: 40.0, maxHeight: 200.0),
          ),
        ),
      );

      final container = find.byType(AnimatedContainer);
      final initialContainerWidget = tester.widget<AnimatedContainer>(
        container,
      );
      final initialHeight =
          initialContainerWidget.constraints?.minHeight ?? 0.0;

      final editorFinder = find.byType(AppFlowyEditor);
      final editor = tester.widget<AppFlowyEditor>(editorFinder);
      final editorState = editor.editorState;

      final transaction = editorState.transaction;
      final docNode = editorState.getNodeAtPath([0]);
      if (docNode != null) {
        // add multiple lines to force height increase
        transaction.replaceText(
          docNode,
          0,
          0,
          'Line 1\nLine 2\nLine 3\nLine 4\nLine 5',
        );
        editorState.apply(transaction);
      }

      // wait for height animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final updatedContainerWidget = tester.widget<AnimatedContainer>(
        container,
      );
      final updatedHeight =
          updatedContainerWidget.constraints?.minHeight ?? 0.0;

      // height should have increased
      expect(updatedHeight, greaterThan(initialHeight));
    });

    testWidgets('respects max height constraint when content grows', (
      tester,
    ) async {
      const maxHeight = 100.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HtmlEditor(editable: true, maxHeight: maxHeight),
          ),
        ),
      );

      final editorFinder = find.byType(AppFlowyEditor);
      final editor = tester.widget<AppFlowyEditor>(editorFinder);
      final editorState = editor.editorState;

      final transaction = editorState.transaction;
      final docNode = editorState.getNodeAtPath([0]);
      if (docNode != null) {
        // Add many lines to try to exceed max height
        transaction.replaceText(
          docNode,
          0,
          0,
          List.generate(20, (i) => 'Line $i').join('\n'),
        );
        editorState.apply(transaction);
      }

      // wait for height animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final container = find.byType(AnimatedContainer);
      final containerWidget = tester.widget<AnimatedContainer>(container);
      final height = containerWidget.constraints?.maxHeight ?? 0.0;
      // verify container height is capped
      expect(height, equals(maxHeight));
    });

    testWidgets('maintains min height when content is empty', (tester) async {
      const minHeight = 50.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HtmlEditor(editable: true, minHeight: minHeight),
          ),
        ),
      );

      final editorFinder = find.byType(AppFlowyEditor);
      final editor = tester.widget<AppFlowyEditor>(editorFinder);
      final editorState = editor.editorState;

      final transaction = editorState.transaction;
      final docNode = editorState.getNodeAtPath([0]);
      if (docNode != null) {
        // add and then remove text
        transaction.replaceText(docNode, 0, 0, 'Some text');
        editorState.apply(transaction);

        final clearTransaction = editorState.transaction;
        clearTransaction.replaceText(docNode, 0, 9, '');
        editorState.apply(clearTransaction);
      }

      // wait for height animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final container = find.byType(AnimatedContainer);
      final containerWidget = tester.widget<AnimatedContainer>(container);
      final height = containerWidget.constraints?.minHeight ?? 0.0;
      // verify container height is at minHeight
      expect(height, equals(minHeight));
    });

    testWidgets('uses minHeight when viewport dimension is zero', (
      tester,
    ) async {
      const minHeight = 50.0;

      await tester.binding.setSurfaceSize(const Size(0, 0));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HtmlEditor(editable: true, minHeight: minHeight),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final container = find.byType(AnimatedContainer);
      final containerWidget = tester.widget<AnimatedContainer>(container);
      final height = containerWidget.constraints?.minHeight ?? 0.0;
      expect(height, equals(minHeight));

      // reset the surface size
      await tester.binding.setSurfaceSize(null);
    });
  });
}
