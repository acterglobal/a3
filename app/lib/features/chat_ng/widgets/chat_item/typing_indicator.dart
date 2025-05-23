import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/acter_theme.dart';
import 'package:acter/common/widgets/typing_indicator.dart';
import 'package:acter/features/chat_ng/providers/chat_typing_event_providers.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TypingIndicator extends ConsumerWidget {
  final String roomId;
  final bool isSelected;

  const TypingIndicator({super.key, required this.roomId, required this.isSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDM = ref.watch(isDirectChatProvider(roomId)).valueOrNull ?? false;

    final typingUsersDisplayNames = ref.watch(
      chatTypingUsersDisplayNameProvider(roomId),
    );
    final lang = L10n.of(context);

    //If there are no typing users, return an empty string
    if (typingUsersDisplayNames.isEmpty) return const SizedBox.shrink();

    if (isDM) {
      return _buildAnimatedCircles(context);
    }

    final theme = Theme.of(context);

    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: _buildAnimatedCircles(context),
        ),
        Expanded(
          child: Text(
            switch (typingUsersDisplayNames.length) {
              1 => lang.typingUser1(typingUsersDisplayNames.first),
              2 => lang.typingUser2(
                typingUsersDisplayNames.first,
                typingUsersDisplayNames.last,
              ),
              _ => lang.typingUserN(
                typingUsersDisplayNames.first,
                typingUsersDisplayNames.length - 1,
              ),
            },
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedCircles(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: AnimatedCircles(
        theme: Theme.of(context).typingIndicatorTheme,
        isSelected: isSelected,
      ),
    );
  }
}
