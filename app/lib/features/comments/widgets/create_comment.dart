import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/html_editor.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class CreateCommentWidget extends ConsumerStatefulWidget {
  final CommentsManager manager;
  final void Function() onClose;
  static const commentField = Key('create-comment-input-field');

  const CreateCommentWidget({
    super.key,
    required this.manager,
    required this.onClose,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CreateCommentWidgetState();
}

class _CreateCommentWidgetState extends ConsumerState<CreateCommentWidget> {
  EditorState textEditorState = EditorState.blank();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: commentInputUI(),
    );
  }

  Widget commentInputUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Text(L10n.of(context).createComment),
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Spacer(),
              OutlinedButton(
                onPressed: widget.onClose,
                child: Text(L10n.of(context).cancel),
              ),
              const SizedBox(width: 22),
              ActerPrimaryActionButton(
                onPressed: onSubmit,
                child: Text(L10n.of(context).submit),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> onSubmit() async {
    final plainDescription = textEditorState.intoMarkdown().trim();
    final htmlBodyDescription = textEditorState.intoHtml();
    if (plainDescription.isEmpty) {
      EasyLoading.showToast(L10n.of(context).youNeedToEnterAComment);
      return;
    }
    EasyLoading.show(status: L10n.of(context).submittingComment);
    try {
      final draft = widget.manager.commentDraft();
      draft.contentFormatted(plainDescription, htmlBodyDescription);
      await draft.send();
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(L10n.of(context).commentSubmitted);
    } catch (e) {
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).errorSubmittingComment(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
