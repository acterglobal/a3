import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/html_editor.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::comments::create_comment');

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
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Text(lang.createComment),
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
              textEditorState = EditorState(
                document: ActerDocumentHelpers.parse(
                  body,
                  htmlContent: html,
                ),
              );
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
                child: Text(lang.cancel),
              ),
              const SizedBox(width: 22),
              ActerPrimaryActionButton(
                onPressed: onSubmit,
                child: Text(lang.submit),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> onSubmit() async {
    final lang = L10n.of(context);
    final plainDescription = textEditorState.intoMarkdown().trim();
    final htmlBodyDescription = textEditorState.intoHtml();
    if (plainDescription.isEmpty) {
      EasyLoading.showToast(lang.youNeedToEnterAComment);
      return;
    }
    EasyLoading.show(status: lang.submittingComment);
    try {
      final draft = widget.manager.commentDraft();
      draft.contentFormatted(plainDescription, htmlBodyDescription);
      await draft.send();
      FocusManager.instance.primaryFocus?.unfocus();
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(lang.commentSubmitted);
    } catch (e, s) {
      _log.severe('Failed to submit comment', e, s);
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.errorSubmittingComment(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
