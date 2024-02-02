import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class SelectActionItem extends StatelessWidget {
  final Function onSpaceItemSelected;
  final Function onChatItemSelected;

  const SelectActionItem({
    super.key,
    required this.onSpaceItemSelected,
    required this.onChatItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20.0),
        actionItemUI(
          context: context,
          actionIcon: Atlas.connection,
          actionName: 'Invite to space',
          onTap: () => onSpaceItemSelected(),
        ),
        const SizedBox(height: 20.0),
        actionItemUI(
          context: context,
          actionIcon: Atlas.message,
          actionName: 'Invite to chat',
          onTap: () => onChatItemSelected(),
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }

  Widget actionItemUI({
    required BuildContext context,
    required IconData actionIcon,
    required String actionName,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(actionIcon),
      title: Text(actionName),
    );
  }
}
