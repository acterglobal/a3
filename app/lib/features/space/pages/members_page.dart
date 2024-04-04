import 'dart:math';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/member/widgets/member_list_entry.dart';
import 'package:acter/features/space/widgets/space_header.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SpaceMembersPage extends ConsumerWidget {
  final String spaceIdOrAlias;

  const SpaceMembersPage({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(spaceProvider(spaceIdOrAlias)).requireValue;
    final members = ref.watch(membersIdsProvider(spaceIdOrAlias));
    final myMembership = ref.watch(roomMembershipProvider(spaceIdOrAlias));
    final List<Widget> topMenu = [
      Expanded(
        child: Text(
          L10n.of(context).members,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    ];

    if (myMembership.hasValue) {
      final membership = myMembership.value!;
      if (membership.canString('CanInvite')) {
        topMenu.add(
          IconButton(
            icon: Icon(
              Atlas.plus_circle_thin,
              color: Theme.of(context).colorScheme.neutral5,
            ),
            iconSize: 28,
            color: Theme.of(context).colorScheme.surface,
            onPressed: () => context.pushNamed(
              Routes.spaceInvite.name,
              pathParameters: {'spaceId': spaceIdOrAlias},
            ),
          ),
        );
      }
    }
    // get platform of context.

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: primaryGradient),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SpaceHeader(spaceIdOrAlias: spaceIdOrAlias),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: topMenu,
              ),
            ),
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
      ),
    );
  }
}
