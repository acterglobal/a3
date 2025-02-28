import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter/features/super_invites/widgets/invite_list_item.dart';
import 'package:acter/features/super_invites/widgets/invite_list_skeleton.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::super-invites::list');

class InviteListWidget extends ConsumerWidget {
  final Function(SuperInviteToken)? onSelectInviteCode;
  const InviteListWidget({super.key, this.onSelectInviteCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final superInviteList = ref.watch(superInvitesTokensProvider);
    return superInviteList.when(
      data: (inviteList) => buildInviteListUI(lang, inviteList),
      error:
          (error, stack) => inviteListErrorWidget(context, ref, error, stack),
      loading: () => const InviteListSkeleton(),
    );
  }

  Widget buildInviteListUI(L10n lang, List<SuperInviteToken> inviteList) {
    if (inviteList.isEmpty) return inviteListEmptyState(lang);
    return ListView.builder(
      itemCount: inviteList.length,
      itemBuilder: (context, index) {
        return InviteListItem(
          inviteToken: inviteList[index],
          onSelectInviteCode: onSelectInviteCode,
        );
      },
    );
  }

  Widget inviteListErrorWidget(
    BuildContext context,
    WidgetRef ref,
    Object error,
    StackTrace stack,
  ) {
    _log.severe('Failed to load invites', error, stack);
    return ErrorPage(
      background: const InviteListSkeleton(),
      error: error,
      stack: stack,
      textBuilder: (error, code) => L10n.of(context).loadingFailed(error),
      onRetryTap: () {
        ref.invalidate(superInvitesTokensProvider);
      },
    );
  }

  Widget inviteListEmptyState(L10n lang) {
    return Column(
      children: [
        SizedBox(height: 40),
        const Icon(Atlas.plus_ticket_thin, size: 50),
        SizedBox(height: 20),
        Text(lang.inviteCodeEmptyState),
      ],
    );
  }
}
