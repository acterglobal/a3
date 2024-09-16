import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/providers/create_chat_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MessageUserButton extends ConsumerWidget {
  final Member member;

  const MessageUserButton({
    super.key,
    required this.member,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(alwaysClientProvider);
    final dmId = client.dmWithUser(member.userId().toString()).text();
    return dmId.let(
          (p0) => Center(
            child: OutlinedButton.icon(
              icon: const Icon(Atlas.chats_thin),
              onPressed: () async {
                Navigator.pop(context);
                goToChat(context, p0);
              },
              label: Text(L10n.of(context).message),
            ),
          ),
        ) ??
        Center(
          child: OutlinedButton.icon(
            icon: const Icon(Atlas.chats_thin),
            onPressed: () {
              ref.read(createChatSelectedUsersProvider.notifier).state = [
                member.getProfile(),
              ];
              Navigator.pop(context);
              context.pushNamed(Routes.createChat.name);
            },
            label: Text(L10n.of(context).startDM),
          ),
        );
  }
}
