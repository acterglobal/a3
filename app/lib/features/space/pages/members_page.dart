import 'dart:core';
import 'dart:math';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/space/widgets/member_list_entry.dart';
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
    // get platform of context.
    return Padding(
      padding: const EdgeInsets.all(20),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Members',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Atlas.plus_circle_thin,
                    color: Theme.of(context).colorScheme.neutral5,
                  ),
                  iconSize: 28,
                  color: Theme.of(context).colorScheme.surface,
                  onPressed: () => context.pushNamed(
                    Routes.actionAddPin.name,
                    queryParameters: {'spaceId': spaceIdOrAlias},
                  ),
                ),
              ],
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
                    child: Text('there is nothing pinned yet'),
                  ),
                );
              }
              return SliverGrid.builder(
                itemCount: members.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: max(1, min(widthCount, minCount)),
                  childAspectRatio: 6,
                ),
                itemBuilder: (context, index) {
                  final member = members[index];
                  return MemberListEntry(
                    member: member,
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
