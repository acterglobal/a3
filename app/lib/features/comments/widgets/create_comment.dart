import 'package:acter/common/widgets/html_editor.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateCommentWidget extends ConsumerStatefulWidget {
  final CommentsManager manager;
  static const commentField = Key('create-comment-input-field');
  const CreateCommentWidget({super.key, required this.manager});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CreateCommentWidgetState();
}

class _CreateCommentWidgetState extends ConsumerState<CreateCommentWidget> {
  EditorState textEditorState = EditorState.blank();
  bool opened = false;

  @override
  Widget build(BuildContext context) {
    if (!opened) {
      return Center(
        child: OutlinedButton.icon(
          onPressed: () => setState(() => opened = true),
          icon: const Icon(Icons.add_comment_outlined),
          label: const Text('comment'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(bottom: 5),
          child: Text('Create Comment'),
        ),
        Container(
          height: 200,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: HtmlEditor(
            key: CreateCommentWidget.commentField,
            editable: true,
            autoFocus: false,
            editorState: textEditorState,
            footer: const SizedBox(),
            onChanged: (body, html) {
              final document = html != null
                  ? ActerDocumentHelpers.fromHtml(html)
                  : ActerDocumentHelpers.fromMarkdown(body);
              textEditorState = EditorState(document: document);
            },
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => setState(() => opened = false),
              child: const Text('cancel'),
            ),
            OutlinedButton(
              onPressed: onSubmit,
              child: const Text('submit'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> onSubmit() async {
    final plainDescription = textEditorState.intoMarkdown().trim();
    final htmlBodyDescription = textEditorState.intoHtml();
    if (plainDescription.isEmpty) {
      EasyLoading.showToast('You need to enter a comment');
      return;
    }
    try {
      EasyLoading.show(status: 'Submitting comment');
      final draft = widget.manager.commentDraft();
      draft.contentFormatted(plainDescription, htmlBodyDescription);
      await draft.send();
      EasyLoading.showToast('Comment submitted');
    } catch (e) {
      EasyLoading.showToast('Error submitting comment: $e');
    }
  }
}
