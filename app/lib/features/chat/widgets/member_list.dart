import 'dart:core';
import 'dart:math';

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/member_list_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemberList extends ConsumerWidget {
  const MemberList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convo = ref.watch(currentConvoProvider);
    final members = ref.watch(chatMembersProvider(convo!.getRoomIdStr()));
    final myMembership =
        ref.watch(spaceMembershipProvider(convo.getRoomIdStr()));

    return members.when(
      data: (members) {
        final widthCount = (MediaQuery.of(context).size.width ~/ 600).toInt();
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
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: max(1, min(widthCount, minCount)),
            childAspectRatio: 6,
          ),
          itemBuilder: (context, index) {
            final member = members[index];
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: MemberListEntry(
                member: member,
                convo: convo,
                myMembership: myMembership.valueOrNull,
              ),
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
    );
  }
}
