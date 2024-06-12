import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/chat/providers/create_chat_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MessageUserButton extends ConsumerWidget {
  final Member member;
  const MessageUserButton({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(alwaysClientProvider);
    final dmId = client.dmWithUser(member.userId().toString()).text();
    if (dmId != null) {
      return Center(
        child: OutlinedButton.icon(
          icon: const Icon(Atlas.chats_thin),
          onPressed: () async {
            context.pop();
            goToChat(context, dmId);
          },
          label: const Text('Message'),
        ),
      );
    } else {
      return Center(
        child: OutlinedButton.icon(
          icon: const Icon(Atlas.chats_thin),
          onPressed: () {
            final profile = member.getProfile();
            ref.read(createChatSelectedUsersProvider.notifier).state = [
              profile,
            ];
            context.pop();
            context.pushNamed(
              Routes.createChat.name,
            );
          },
          label: const Text('Start DM'),
        ),
      );
    }
  }
}
