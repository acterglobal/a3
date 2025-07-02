import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/toolkit/html_editor/html_editor.dart';
import 'package:acter/common/utils/utils.dart';
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
    showDragHandle: false,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
        bottomLeft: Radius.circular(0),
        bottomRight: Radius.circular(0),
      ),
    ),
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
  late EditorState textEditorState;

  @override
  void initState() {
    super.initState();

    final hasValidContent = hasValidEditorContent(
        plainText: widget.descriptionMarkdownValue ?? '',
        html: widget.descriptionHtmlValue ?? '');

    if (hasValidContent) {
      // Use existing content
      textEditorState = ActerEditorStateHelpers.fromContent(
        widget.descriptionMarkdownValue ?? '',
        widget.descriptionHtmlValue,
      );
    } else {
      // Use blank editor with initial text for empty state
      textEditorState = EditorState.blank(withInitialText: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.bottomSheetTitle ?? lang.editDescription,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: brandColor),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: HtmlEditor(
                editorState: textEditorState,
                editable: true,
                hintText: lang.addDescription,
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
