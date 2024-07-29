import 'dart:math';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/member/widgets/member_list_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

class SpaceMembersPage extends ConsumerWidget {
  final String spaceIdOrAlias;

  const SpaceMembersPage({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(membersIdsProvider(spaceIdOrAlias));
    final membership =
        ref.watch(roomMembershipProvider(spaceIdOrAlias)).valueOrNull;
    final invited =
        ref.watch(spaceInvitedMembersProvider(spaceIdOrAlias)).valueOrNull ??
            [];
    final showInviteBtn = membership?.canString('CanInvite') == true;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          actions: [
            showInviteBtn && invited.length <= 100
                ? OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    onPressed: () => context.pushNamed(
                      Routes.spaceInvite.name,
                      pathParameters: {'spaceId': spaceIdOrAlias},
                    ),
                    child: Text(L10n.of(context).invite),
                  )
                : const SizedBox.shrink(),
          ],
        ),
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
                  roomId: spaceIdOrAlias,
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
