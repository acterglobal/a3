import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/invitations/providers/invitations_providers.dart';
import 'package:acter/features/invitations/widgets/has_invites_tile.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ImportantActivitiesSection extends ConsumerWidget {
  const ImportantActivitiesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitations = ref.watch(invitationListProvider);
    final lang = L10n.of(context);

    if (invitations.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          SectionHeader(
            title: lang.pendingInvites,
            showSectionBg: false,
            isShowSeeAllButton: false,
            onTapSeeAll: () => context.pushNamed(Routes.myOpenInvitations.name),
          ),
          HasInvitesTile(count: invitations.length),
        ],
      );
    }
    return Container();
  }
}
