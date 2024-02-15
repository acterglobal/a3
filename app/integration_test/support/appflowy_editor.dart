import 'package:acter/common/widgets/html_editor.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

extension ActerAppflowyEditor on ConvenientTest {
  Future<void> enterIntoAppflowyEditor(
    Key editorKey,
    String text,
  ) async {
    final editorFinder = find.byKey(editorKey);
    await editorFinder.should(findsOneWidget);
    final editorState =
        (tester.firstState(editorFinder) as HtmlEditorState).editorState;
    assert(editorState.editable, 'Editor $editorKey is not editable');
    await editorState.insertTextAtPosition(text);
  }
}
