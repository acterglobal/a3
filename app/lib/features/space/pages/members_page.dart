import 'dart:core';
import 'dart:math';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/member_list_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:go_router/go_router.dart';

class SpaceMembersPage extends ConsumerWidget {
  final String spaceIdOrAlias;
  const SpaceMembersPage({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(spaceProvider(spaceIdOrAlias)).requireValue;
    final members = ref.watch(spaceMembersProvider(spaceIdOrAlias));
    final myMembership = ref.watch(spaceMembershipProvider(spaceIdOrAlias));
    final List<Widget> topMenu = [
      Expanded(
        child: Text(
          'Members',
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

    return Padding(
      padding: const EdgeInsets.all(20),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Row(
              children: topMenu,
            ),
          ),
          members.when(
            data: (members) {
              final widthCount =
                  (MediaQuery.of(context).size.width ~/ 600).toInt();
              const int minCount = 2;
              if (members.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      'No members found. How can that even be, you are here, aren\'t you?',
                    ),
                  ),
                );
              }
              return SliverGrid.builder(
                itemCount: members.length,
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
                  crossAxisCount: max(1, min(widthCount, minCount)),
                  height: MediaQuery.of(context).size.height * 0.1,
                ),
                itemBuilder: (context, index) {
                  final member = members[index];
                  return MemberListEntry(
                    member: member,
                    space: space,
                    myMembership: myMembership.valueOrNull,
                  );
                },
              );
            },
            error: (error, stack) => SliverToBoxAdapter(
              child: Center(
                child: Text('Loading failed: $error'),
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Text('Loading'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
