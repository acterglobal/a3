import 'package:acter/common/widgets/html_editor/components/room_mention_block.dart';
import 'package:acter/common/widgets/html_editor/components/user_mention_block.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

enum MentionType {
  user,
  room;

  static MentionType fromString(String value) => switch (value) {
        'user' => user,
        'room' => room,
        _ => throw UnimplementedError(),
      };
}

class MentionBlockKeys {
  const MentionBlockKeys._();
  static const mention = 'mention';
  static const type = 'type'; // MentionType, String
  static const blockId = 'block_id';
  static const userId = 'user_id';
  static const roomId = 'room_id';
  static const displayName = 'display_name';
  static const userMentionChar = '@';
  static const roomMentionChar = '#';
}

class MentionBlock extends StatelessWidget {
  const MentionBlock({
    super.key,
    required this.editorState,
    required this.mention,
    required this.node,
    required this.index,
    required this.textStyle,
  });

  final EditorState editorState;
  final Map<String, dynamic> mention;
  final Node node;
  final int index;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final type = MentionType.fromString(mention[MentionBlockKeys.type]);

    switch (type) {
      case MentionType.user:
        final String? userId = mention[MentionBlockKeys.userId] as String?;
        final String? displayName =
            mention[MentionBlockKeys.displayName] as String?;
        if (userId == null) {
          return const SizedBox.shrink();
        }

        final String? blockId = mention[MentionBlockKeys.blockId] as String?;

        return UserMentionBlock(
          key: ValueKey(userId),
          editorState: editorState,
          displayName: displayName,
          userId: userId,
          blockId: blockId,
          node: node,
          textStyle: textStyle,
          index: index,
        );
      case MentionType.room:
        final String? roomId = mention[MentionBlockKeys.roomId] as String?;
        final String? displayName =
            mention[MentionBlockKeys.displayName] as String?;
        if (roomId == null) {
          return const SizedBox.shrink();
        }
        final String? blockId = mention[MentionBlockKeys.blockId] as String?;

        return RoomMentionBlock(
          key: ValueKey(roomId),
          editorState: editorState,
          displayName: displayName,
          roomId: roomId,
          blockId: blockId,
          node: node,
          textStyle: textStyle,
          index: index,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
