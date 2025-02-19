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
    final lang = L10n.of(context);
    final membersLoader = ref.watch(membersIdsProvider(spaceId));
    return membersLoader.when(
      data: (members) => buildMembersSectionUI(context, members),
      error: (e, s) {
        _log.severe('Failed to load members in space', e, s);
        return Center(
          child: Text(lang.loadingMembersFailed(e)),
        );
      },
      loading: () => Center(
        child: Text(lang.loading),
      ),
    );
  }

  Widget buildMembersSectionUI(BuildContext context, List<String> members) {
    final hasMore = members.length > limit;
    final count = hasMore ? limit : members.length;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: L10n.of(context).members,
          isShowSeeAllButton: hasMore,
          onTapSeeAll: () => context.pushNamed(
            Routes.spaceMembers.name,
            pathParameters: {'spaceId': spaceId},
          ),
        ),
        membersListUI(members, count),
      ],
    );
  }

  Widget membersListUI(List<String> members, int count) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: count,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => MemberListEntry(
        memberId: members[index],
        roomId: spaceId,
      ),
    );
  }
}
