import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::space::non_acter_space_card');

class NonActerSpaceCard extends ConsumerWidget {
  final String spaceId;

  const NonActerSpaceCard({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myMembership = ref.watch(roomMembershipProvider(spaceId));
    var fallback = Text(
      'Ask a space admin to convert this into an acter space to unlock these features',
      style: Theme.of(context).textTheme.bodySmall,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Not an acter space',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            'This space has not been created with acter and therefore lacks many features',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          myMembership.when(
            data: (membership) {
              if (membership != null &&
                  membership.canString('CanUpgradeToActerSpace')) {
                return OutlinedButton(
                  onPressed: () => upgradeSpace(context, ref),
                  child: const Text('Upgrade to Acter space'),
                );
              } else {
                return fallback;
              }
            },
            error: (error, stack) => Text('Loading failed: $error'),
            loading: () => fallback,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void upgradeSpace(BuildContext context, WidgetRef ref) async {
    customMsgSnackbar(context, 'Converting to acter space');

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
        'Successfully upgraded to Acter space. Enjoy!',
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      context.pop();
      customMsgSnackbar(context, 'Upgrade failed: $e');
    }
  }
}
