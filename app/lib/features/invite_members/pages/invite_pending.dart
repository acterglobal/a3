import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/member/widgets/user_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class InvitePending extends ConsumerWidget {
  final String roomId;

  const InvitePending({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context, ref),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(L10n.of(context).pendingInvites),
      centerTitle: true,
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final invited =
        ref.watch(roomInvitedMembersProvider(roomId)).valueOrNull ?? [];

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        alignment: Alignment.topCenter,
        child: invited.isEmpty
            ? EmptyState(
                title: L10n.of(context).noPendingInvitesTitle,
                image: 'assets/images/empty_chat.svg',
              )
            : ListView.builder(
                itemCount: invited.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return UserBuilder(
                    userId: invited[index].userId().toString(),
                    roomId: roomId,
                  );
                },
              ),
      ),
    );
  }
}
