import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

final _log = Logger('a3::space::non_acter_space_card');

class NonActerSpaceCard extends ConsumerWidget {
  final String spaceId;

  const NonActerSpaceCard({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myMembership = ref.watch(roomMembershipProvider(spaceId));
    var fallback = Text(
      L10n.of(context).askASpaceAdminToConvertThis,
      style: Theme.of(context).textTheme.bodySmall,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L10n.of(context).notAnActerSpace,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            L10n.of(context).thisSpaceHasNotBeenCreatedWithActer,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          myMembership.when(
            data: (membership) {
              if (membership?.canString('CanUpgradeToActerSpace') == true) {
                return OutlinedButton(
                  onPressed: () => upgradeSpace(context, ref),
                  child: Text(L10n.of(context).upgradeToActerSpace),
                );
              } else {
                return fallback;
              }
            },
            error: (error, stack) => Text(
              '${L10n.of(context).loading}: $error',
            ),
            loading: () => fallback,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void upgradeSpace(BuildContext context, WidgetRef ref) async {
    customMsgSnackbar(context, L10n.of(context).convertingToActerSpace);

    try {
      final space = await ref.read(spaceProvider(spaceId).future);
      _log.info('before setting space state');

      await space.setActerSpaceStates();
      _log.info('after setting space state');
      // We are doing as expected, but the lint still triggers.
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }
      customMsgSnackbar(
        context,
        L10n.of(context).successfullyUpgradedToActerSpace,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      context.pop();
      customMsgSnackbar(context, '${L10n.of(context).upgradeFailed}: $e');
    }
  }
}
