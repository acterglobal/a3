import 'dart:core';

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/member_list_entry.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemberList extends ConsumerWidget {
  final Convo convo;
  const MemberList({
    required this.convo,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = convo.getRoomIdStr();
    final members = ref.watch(chatMembersProvider(roomId));
    final myMembership = ref.watch(spaceMembershipProvider(roomId));

    return members.when(
      data: (members) {
        if (members.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Text(
                'No members found. How can that even be, you are here, aren\'t you?',
              ),
            ),
          );
        }
        return SliverList.builder(
          itemCount: members.length,
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
