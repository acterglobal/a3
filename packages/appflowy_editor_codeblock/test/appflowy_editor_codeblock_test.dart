import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_codeblock/code_block_block_component.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Smoke tests', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    test('we see code block', () async {
      final document =
          Document.blank()..insert([0], [codeBlockNode(language: 'dart')]);

      final editorState = EditorState(document: document);

      editorState.selection = Selection.collapsed(Position(path: [0]));

      expect(editorState.getNodeAtPath([0])?.type, CodeBlockKeys.type);
    });
  });
}
