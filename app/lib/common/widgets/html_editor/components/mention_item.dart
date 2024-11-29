import 'package:acter/common/extensions/options.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';

class MentionItem extends StatelessWidget {
  const MentionItem({
    super.key,
    required this.mentionId,
    required this.displayName,
    required this.avatarOptions,
    required this.isSelected,
    required this.onTap,
  });

  final String mentionId;
  final String? displayName;
  final AvatarOptions avatarOptions;
  final bool isSelected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasKeyboard =
        MediaQuery.of(context).navigationMode == NavigationMode.directional;

    return Container(
      height: 60,
      color: (isSelected && hasKeyboard)
          ? Theme.of(context).colorScheme.primary
          : null,
      child: ListTile(
        dense: true,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: ActerAvatar(options: avatarOptions),
        title: Text(
          displayName ?? mentionId,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        subtitle: displayName.map(
          (name) => Text(name, style: Theme.of(context).textTheme.labelMedium),
          orElse: () => null,
        ),
      ),
    );
  }
}
