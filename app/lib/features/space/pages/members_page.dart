import 'dart:math';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/member/widgets/member_list_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SpaceMembersPage extends ConsumerWidget {
  final String spaceIdOrAlias;

  const SpaceMembersPage({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(spaceProvider(spaceIdOrAlias)).requireValue;
    final members = ref.watch(membersIdsProvider(spaceIdOrAlias));

    return CustomScrollView(
      slivers: [
        const SliverAppBar(),
        members.when(
          data: (members) {
            final widthCount =
                (MediaQuery.of(context).size.width ~/ 300).toInt();
            const int minCount = 4;
            if (members.isEmpty) {
              return SliverToBoxAdapter(
                child: Center(
                  child: Text(
                    L10n.of(context).noMembersFound,
                  ),
                ),
              );
            }
            return SliverGrid.builder(
              itemCount: members.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: max(1, min(widthCount, minCount)),
                childAspectRatio: 5.0,
              ),
              itemBuilder: (context, index) {
                return MemberListEntry(
                  memberId: members[index],
                  roomId: space.getRoomIdStr(),
                );
              },
            );
          },
          error: (error, stack) => SliverToBoxAdapter(
            child: Center(
              child: Text(L10n.of(context).loadingFailed(error)),
            ),
          ),
          loading: () => SliverToBoxAdapter(
            child: Center(
              child: Text(L10n.of(context).loading),
            ),
          ),
        ),
      ],
    );
  }
}
