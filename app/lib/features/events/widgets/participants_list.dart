import 'package:acter/features/member/widgets/member_list_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ParticipantsList extends ConsumerWidget {
  final String roomId;
  final List<String> participants;

  const ParticipantsList({
    super.key,
    required this.roomId,
    required this.participants,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(L10n.of(context).eventParticipants),
              ),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(L10n.of(context).close),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                ...participants.map(
                  (a) => MemberListEntry(
                    memberId: a,
                    roomId: roomId,
                    isShowActions: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
