import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/features/member/widgets/member_list_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class MembersSection extends ConsumerWidget {
  final String spaceId;
  final int limit;

  const MembersSection({
    super.key,
    required this.spaceId,
    this.limit = 3,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        membersLabel(context),
        membersList(context, ref),
      ],
    );
  }

  Widget membersLabel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Text(
            L10n.of(context).members,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          ActerInlineTextButton(
            onPressed: () {},
            child: Text(L10n.of(context).seeAll),
          ),
        ],
      ),
    );
  }

  Widget membersList(BuildContext context, WidgetRef ref) {
    final membersList = ref.watch(membersIdsProvider(spaceId));

    return membersList.when(
      data: (members) {
        int membersLimit = (members.length > limit) ? limit : members.length;
        return ListView.builder(
          shrinkWrap: true,
          itemCount: membersLimit,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return MemberListEntry(
              memberId: members[index],
              roomId: spaceId,
            );
          },
        );
      },
      error: (error, stack) =>
          Center(child: Text(L10n.of(context).loadingFailed(error))),
      loading: () => Center(
        child: Text(L10n.of(context).loading),
      ),
    );
  }
}
