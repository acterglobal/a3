import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/invitations/widgets/invitation_item_widget.dart';
import 'package:acter/features/invitations/providers/invitations_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/l10n/l10n.dart';

class InvitesPage extends ConsumerWidget {
  const InvitesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(L10n.of(context).invitations),
      ),
      body: _buildBody(context, ref),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final invitations = ref.watch(invitationListProvider);
    if (invitations.isEmpty) {
      return Center(
        heightFactor: 1.5,
        child: EmptyState(
          title: L10n.of(context).noPendingInvitesTitle,
          image: 'assets/images/empty_activity.svg',
        ),
      );
    }
    return ListView.builder(
      itemBuilder:
          (context, index) =>
              InvitationItemWidget(invitation: invitations[index]),
      itemCount: invitations.length,
    );
  }
}
