import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/html_editor/html_editor.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void showEditHtmlDescriptionBottomSheet({
  required BuildContext context,
  String? bottomSheetTitle,
  String? descriptionHtmlValue,
  String? descriptionMarkdownValue,
  required Function(WidgetRef, String, String) onSave,
}) {
  showModalBottomSheet(
    showDragHandle: true,
    useSafeArea: true,
    context: context,
    isDismissible: true,
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
  final Function(WidgetRef, String, String) onSave;

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
    final document = ActerDocumentHelpers.parse(
      widget.descriptionMarkdownValue ?? '',
      htmlContent: widget.descriptionHtmlValue,
    );
    if (!document.isEmpty) {
      textEditorState = EditorState(document: document);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.bottomSheetTitle ?? lang.editDescription),
          const SizedBox(height: 20),
          Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: brandColor),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: HtmlEditor(editorState: textEditorState, editable: true),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(lang.cancel),
              ),
              const SizedBox(width: 20),
              ActerPrimaryActionButton(
                onPressed: () {
                  // No need to change
                  String htmlBodyDescription = textEditorState.intoHtml();
                  final plainDescription = textEditorState.intoMarkdown();
                  if (htmlBodyDescription == widget.descriptionHtmlValue ||
                      plainDescription == widget.descriptionMarkdownValue) {
                    Navigator.pop(context);
                    return;
                  }

                  widget.onSave(ref, htmlBodyDescription, plainDescription);
                },
                child: Text(lang.save),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
