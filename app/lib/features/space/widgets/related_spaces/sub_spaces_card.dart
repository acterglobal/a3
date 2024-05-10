import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/space/widgets/related_spaces/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SubSpacesCard extends ConsumerWidget {
  final String spaceId;

  const SubSpacesCard({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(spaceRelationsOverviewProvider(spaceId));

    return spaces.when(
      data: (spaces) {
        final subSpaces = renderSubSpaces(
          context,
          spaceId,
          spaces,
          titleBuilder: () => Row(
            children: [
              Text(
                L10n.of(context).spaces,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        );
        if (subSpaces != null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: subSpaces,
          );
        } else {
          return const SizedBox.shrink();
        }
      },
      error: (error, stack) =>
          Text(L10n.of(context).loadingSpacesFailed(error)),
      loading: () => Text(L10n.of(context).loading),
    );
  }
}
