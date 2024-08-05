import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/member/widgets/member_list_entry.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::space::sections::members');

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
    final membersList = ref.watch(membersIdsProvider(spaceId));
    return membersList.when(
      data: (members) => buildMembersSectionUI(context, members),
      error: (error, stack) {
        _log.severe('Fetching of member list failed', error, stack);
        return Center(
          child: Text(L10n.of(context).loadingFailed(error)),
        );
      },
      loading: () => Center(
        child: Text(L10n.of(context).loading),
      ),
    );
  }

  Widget buildMembersSectionUI(BuildContext context, List<String> members) {
    int membersLimit = (members.length > limit) ? limit : members.length;
    bool isShowSeeAllButton = members.length > membersLimit;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: L10n.of(context).members,
          isShowSeeAllButton: isShowSeeAllButton,
          onTapSeeAll: () => context.pushNamed(
            Routes.spaceMembers.name,
            pathParameters: {'spaceId': spaceId},
          ),
        ),
        membersListUI(members, membersLimit),
      ],
    );
  }

  Widget membersListUI(List<String> members, int membersLimit) {
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
  }
}
