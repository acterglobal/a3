import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat/widgets/skeletons/members_list_skeleton_widget.dart';
import 'package:acter/features/member/widgets/member_list_entry.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::chat::member_list');

class MemberList extends ConsumerWidget {
  final String roomId;

  const MemberList({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchValue = ref.watch(searchValueProvider);
    final membersLoader = ref.watch(
      membersIdWithSearchProvider((roomId: roomId, searchValue: searchValue)),
    );
    final lang = L10n.of(context);
    return membersLoader.when(
      data: (members) {
        if (members.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: Text(lang.noMembersFound),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 5),
          itemCount: members.length,
          itemBuilder:
              (context, index) => Padding(
                padding: const EdgeInsets.all(8),
                child: MemberListEntry(
                  memberId: members[index],
                  roomId: roomId,
                ),
              ),
        );
      },
      error: (e, s) {
        _log.severe('Failed to load room members', e, s);
        return Center(child: Text(lang.loadingFailed(e)));
      },
      loading: () => const MembersListSkeleton(),
    );
  }
}
