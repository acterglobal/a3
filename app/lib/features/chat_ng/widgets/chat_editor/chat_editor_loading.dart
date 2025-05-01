import 'package:acter/common/toolkit/html_editor/html_editor.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

//  loading state widget
class ChatEditorLoading extends StatelessWidget {
  const ChatEditorLoading({super.key});

  @override
  Widget build(BuildContext context) => Skeletonizer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.emoji_emotions, size: 20),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).unselectedWidgetColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const SingleChildScrollView(
                child: IntrinsicHeight(
                  child: HtmlEditor(
                    footer: null,
                    editable: true,
                    shrinkWrap: true,
                    editorPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Atlas.paperclip_attachment_thin, size: 20),
          ),
        ],
      ),
    ),
  );
}
