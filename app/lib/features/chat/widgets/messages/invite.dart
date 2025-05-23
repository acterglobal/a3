import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class InviteSystemMessageWidget extends ConsumerWidget {
  final SystemMessage message;
  final String roomId;

  const InviteSystemMessageWidget({
    super.key,
    required this.roomId,
    required this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(roomMembershipProvider(roomId)).valueOrNull;
    if (membership?.canString('CanInvite') != true) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 15),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          onPressed: () {
            context.pushNamed(
              Routes.chatInvite.name,
              pathParameters: {'roomId': roomId},
            );
          },
          child: Text(L10n.of(context).invite),
        ),
      ),
    );
  }
}
