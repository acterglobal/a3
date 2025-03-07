import 'package:acter/common/models/types.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/home/widgets/badged_icon.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatsIcon extends ConsumerWidget {
  const ChatsIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urgency =
        ref.watch(hasUnreadChatsProvider).valueOrNull ?? UrgencyBadge.none;
    return BadgedIcon(
      urgency: urgency,
      child: const Icon(Atlas.chats_thin, key: MainNavKeys.chats, size: 18),
    );
  }
}
