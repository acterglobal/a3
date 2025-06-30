import 'package:acter/features/invitations/providers/invitations_providers.dart';
import 'package:acter/features/invitations/widgets/has_invites_tile.dart';
import 'package:acter/features/invitations/widgets/invitation_item_widget.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InvitationSectionWidget extends ConsumerWidget {
  const InvitationSectionWidget({super.key});

  static bool shouldBeShown(WidgetRef ref) => getInvitations(ref).isNotEmpty;

  static List<RoomInvitation> getInvitations(WidgetRef ref) =>
      ref.watch(invitationListProvider).valueOrNull ?? <RoomInvitation>[];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!shouldBeShown(ref)) return const SizedBox.shrink();
    final invitations = getInvitations(ref);
    return Column(
      children: [
        SectionHeader(
          title: L10n.of(context).invitations,
          showSectionBg: false,
          isShowSeeAllButton: false,
        ),
        invitations.length == 1
            ? InvitationItemWidget(invitation: invitations.first)
            : HasInvitesTile(count: invitations.length),
      ],
    );
  }
}
