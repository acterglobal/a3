import 'package:acter/common/widgets/html_editor/models/mention_type.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';

class MentionItem extends StatelessWidget {
  const MentionItem({
    super.key,
    required this.mentionId,
    required this.mentionType,
    required this.displayName,
    required this.avatarOptions,
    required this.isSelected,
    required this.onTap,
  });

  final String mentionId;
  final MentionType mentionType;
  final String displayName;
  final AvatarOptions avatarOptions;
  final bool isSelected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: isSelected ? Theme.of(context).colorScheme.primary : null,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: ActerAvatar(options: avatarOptions),
        title: Text(
          displayName.isNotEmpty ? displayName : mentionId,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        subtitle: displayName.isNotEmpty
            ? Text(mentionId, style: Theme.of(context).textTheme.labelMedium)
            : null,
      ),
    );
  }
}
