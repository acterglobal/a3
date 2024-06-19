import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/html_editor.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

void showEditHtmlDescriptionBottomSheet({
  required BuildContext context,
  String? bottomSheetTitle,
  String? descriptionHtmlValue,
  String? descriptionMarkdownValue,
  required Function(EditorState) onSave,
}) {
  showModalBottomSheet(
    showDragHandle: true,
    useSafeArea: true,
    context: context,
    isDismissible: true,
    constraints: const BoxConstraints(maxHeight: 450),
    isScrollControlled: true,
    builder: (context) {
      return EditHtmlDescriptionSheet(
        bottomSheetTitle: bottomSheetTitle,
        descriptionHtmlValue: descriptionHtmlValue,
        descriptionMarkdownValue: descriptionMarkdownValue,
        onSave: onSave,
      );
    },
  );
}

class EditHtmlDescriptionSheet extends ConsumerStatefulWidget {
  final String? bottomSheetTitle;
  final String? descriptionHtmlValue;
  final String? descriptionMarkdownValue;
  final Function(EditorState) onSave;

  const EditHtmlDescriptionSheet({
    super.key,
    this.bottomSheetTitle,
    required this.descriptionHtmlValue,
    required this.descriptionMarkdownValue,
    required this.onSave,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _EditHtmlDescriptionSheetState();
}

class _EditHtmlDescriptionSheetState
    extends ConsumerState<EditHtmlDescriptionSheet> {
  EditorState textEditorState = EditorState.blank();

  @override
  void initState() {
    super.initState();
    final document = widget.descriptionHtmlValue != null
        ? ActerDocumentHelpers.fromHtml(
            widget.descriptionHtmlValue!,
          )
        : ActerDocumentHelpers.fromMarkdown(
            widget.descriptionMarkdownValue ?? '',
          );
    textEditorState = EditorState(document: document);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          Text(widget.bottomSheetTitle ?? L10n.of(context).editDescription),
          const SizedBox(height: 20),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: brandColor),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: HtmlEditor(
              editorState: textEditorState,
              editable: true,
              autoFocus: true,
              onChanged: (body, html) {
                final document = html != null
                    ? ActerDocumentHelpers.fromHtml(html)
                    : ActerDocumentHelpers.fromMarkdown(body);
                textEditorState = EditorState(document: document);
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => context.pop(),
                child: Text(L10n.of(context).cancel),
              ),
              const SizedBox(width: 20),
              ActerPrimaryActionButton(
                onPressed: () {
                  // No need to change
                  final htmlBodyDescription = textEditorState.intoHtml();
                  final plainDescription = textEditorState.intoMarkdown();
                  if (htmlBodyDescription == widget.descriptionHtmlValue ||
                      plainDescription == widget.descriptionMarkdownValue) {
                    context.pop();
                    return;
                  }

                  // Need to update change of tile
                  widget.onSave(textEditorState);
                },
                child: Text(L10n.of(context).save),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
