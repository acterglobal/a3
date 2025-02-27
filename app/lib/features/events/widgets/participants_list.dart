import 'package:acter/features/member/widgets/member_list_entry.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(child: Text(lang.eventParticipants)),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(lang.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final memberId in participants)
                  MemberListEntry(
                    memberId: memberId,
                    roomId: roomId,
                    isShowActions: false,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
