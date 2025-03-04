import 'package:acter/features/chat_ng/widgets/chat_editor/chat_editor_view.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';

// no permission state widget
class ChatEditorNoAccess extends StatelessWidget {
  const ChatEditorNoAccess({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
    child: Row(
      children: [
        const SizedBox(width: 1),
        Icon(
          Atlas.block_prohibited_thin,
          size: 14,
          color: Theme.of(context).unselectedWidgetColor,
        ),
        const SizedBox(width: 4),
        Text(
          key: ChatEditorView.noAccessKey,
          L10n.of(context).chatMissingPermissionsToSend,
          style: TextStyle(color: Theme.of(context).unselectedWidgetColor),
        ),
      ],
    ),
  );
}
