import 'package:acter/common/dialogs/pop_up_dialog.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NonActerSpaceCard extends ConsumerWidget {
  final String spaceId;
  const NonActerSpaceCard({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myMembership = ref.watch(spaceMembershipProvider(spaceId));
    const fallback = Text(
      'Ask a space admin to convert this into an acter space to unlock these features',
    );
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Not an acter space',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text(
              'This space has not been created with acter and therefor lacks many features',
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
      ),
    );
  }

  void upgradeSpace(BuildContext context, WidgetRef ref) async {
    customMsgSnackbar(context, 'Converting to acetr space');

    try {
      final space = await ref.watch(spaceProvider(spaceId).future);
      debugPrint('before setting space state');

      await space.setActerSpaceStates();
      debugPrint('after setting space state');
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
