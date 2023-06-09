import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/invitation_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InvitationsList extends ConsumerWidget {
  const InvitationsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitations = ref.watch(invitationListProvider);
    if (invitations.isEmpty) {
      return const SizedBox();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.only(left: 18),
          child: Text(
            AppLocalizations.of(context)!.invitedRooms,
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: invitations.length,
          itemBuilder: (BuildContext context, int index) {
            return InvitationCard(
              invitation: invitations[index],
              avatarColor: Colors.white,
            );
          },
        ),
        Container(
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.only(left: 18, top: 10),
          child: Text(
            AppLocalizations.of(context)!.joinedRooms,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
