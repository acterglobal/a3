import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TextMessageWidget extends ConsumerWidget {
  final String roomId;
  final String message;

  const TextMessageWidget({
    super.key,
    required this.roomId,
    required this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textStyle = lastMessageTextStyle(context, ref, roomId);
    return Text(
      message,
      maxLines: 2,
      style: textStyle,
      overflow: TextOverflow.ellipsis,
    );
  }
}

TextStyle? lastMessageTextStyle(
  BuildContext context,
  WidgetRef ref,
  String roomId,
) {
  final theme = Theme.of(context);
  final isUnread = ref.watch(hasUnreadMessages(roomId)).valueOrNull ?? false;
  final color =
      isUnread ? theme.colorScheme.onSurface : theme.colorScheme.surfaceTint;
  final textStyle = theme.textTheme.bodySmall?.copyWith(
    color: color,
    fontSize: 13,
  );
  return textStyle;
}
