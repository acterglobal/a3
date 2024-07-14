import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat/widgets/skeletons/members_list_skeleton_widget.dart';
import 'package:acter/features/member/widgets/member_list_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class MemberList extends ConsumerWidget {
  final String roomId;

  const MemberList({
    required this.roomId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(membersIdsProvider(roomId));

    return members.when(
      data: (members) {
        if (members.isEmpty) {
          return Center(
            child: Text(
              L10n.of(context).noMembersFound,
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 5),
          itemCount: members.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: MemberListEntry(
                memberId: members[index],
                roomId: roomId,
              ),
            );
          },
        );
      },
      error: (error, stack) => Center(
        child: Text(L10n.of(context).loadingFailed(error)),
      ),
      loading: () => const MembersListSkeleton(),
    );
  }
}
