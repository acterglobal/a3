import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/html_editor/models/mention_attributes.dart';
import 'package:acter/common/toolkit/html_editor/models/mention_type.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MentionBlock extends ConsumerWidget {
  final MentionAttributes mentionAttributes;
  final String userRoomId;
  final Node node;
  final int index;

  const MentionBlock({
    super.key,
    required this.node,
    required this.index,
    required this.mentionAttributes,
    required this.userRoomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MentionType type = mentionAttributes.type;
    final String? displayName = mentionAttributes.displayName;
    final String mentionId = mentionAttributes.mentionId;

    final options = switch (type) {
      MentionType.user => AvatarOptions.DM(
        ref.watch(
          memberAvatarInfoProvider((roomId: userRoomId, userId: mentionId)),
        ),
        size: 8,
      ),
      MentionType.room => AvatarOptions(
        ref.watch(roomAvatarInfoProvider(mentionId)),
        size: 16,
      ),
    };

    return _mentionContent(
      context: context,
      mentionId: mentionId,
      displayName: displayName,
      avatarOptions: options,
      ref: ref,
    );
  }

  Widget _mentionContent({
    required BuildContext context,
    required String mentionId,
    required WidgetRef ref,
    required AvatarOptions avatarOptions,
    String? displayName,
  }) {
    final hasMouseConnected =
        RendererBinding.instance.mouseTracker.mouseIsConnected;
    final name = displayName ?? mentionId;
    final mentionContentWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).unselectedWidgetColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ActerAvatar(options: avatarOptions),
          const SizedBox(width: 4),
          Text(name, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );

    final Widget content = GestureDetector(
      onTap: _handleUserTap,
      behavior: HitTestBehavior.opaque,
      child:
          hasMouseConnected
              ? MouseRegion(
                cursor: SystemMouseCursors.click,
                child: mentionContentWidget,
              )
              : mentionContentWidget,
    );

    return content;
  }

  void _handleUserTap() {
    // Implement user tap action (e.g., show profile, start chat)
  }
}
