import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter/features/super_invites/widgets/invite_list_item.dart';
import 'package:acter/features/super_invites/widgets/invite_list_skeleton.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::super-invites::list');

class InviteListWidget extends ConsumerWidget {
  const InviteListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final superInviteList = ref.watch(superInvitesTokensProvider);
    return superInviteList.when(
      data: (inviteList) => buildInviteListUI(inviteList),
      error: (error, stack) =>
          inviteListErrorWidget(context, ref, error, stack),
      loading: () => const InviteListSkeleton(),
    );
  }

  Widget buildInviteListUI(List<SuperInviteToken> inviteList) {
    return ListView.builder(
      itemCount: inviteList.length,
      itemBuilder: (context, index) {
        return InviteListItem(inviteToken: inviteList[index]);
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
}
