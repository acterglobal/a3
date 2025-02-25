import 'package:acter/features/invitations/providers/invitations_providers.dart';
import 'package:acter/features/invitations/widgets/has_invites_tile.dart';
import 'package:acter/features/invitations/widgets/invitation_item_widget.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InvitationWidget extends ConsumerWidget {
  const InvitationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitations = ref.watch(invitationListProvider);
    if (invitations.isEmpty) return SizedBox.shrink();

    return Column(
      children: [
        SectionHeader(
          title: L10n.of(context).invitations,
          showSectionBg: false,
          isShowSeeAllButton: false,
        ),
        invitations.length == 1
            ? InvitationItemWidget(
                invitation: invitations.first,
              )
            : HasInvitesTile(count: invitations.length),
      ],
    );
  }
}
