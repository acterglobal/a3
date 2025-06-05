import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';

typedef MentionTap = void Function(String mentionId, {String? displayName});

class MentionItem extends StatelessWidget {
  const MentionItem({
    super.key,
    required this.mentionId,
    required this.displayName,
    required this.avatarOptions,
    required this.onTap,
  });

  final String mentionId;
  final String? displayName;
  final AvatarOptions avatarOptions;

  final MentionTap onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      onTap: () => onTap(mentionId, displayName: displayName),
      leading: ActerAvatar(options: avatarOptions),
      title: Text(displayName ?? mentionId),
      subtitle: displayName != null ? Text(mentionId) : null,
    );
  }
}
