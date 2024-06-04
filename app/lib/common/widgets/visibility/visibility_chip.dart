import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class VisibilityChip extends ConsumerWidget {
  final String roomId;

  const VisibilityChip({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(spaceProvider(roomId));
    return space.when(
      data: (space) {
        final joinRule = space.joinRuleStr();
        return renderSpaceChip(context, joinRule);
      },
      error: (error, st) => Chip(
        label: Text(L10n.of(context).loadingFailed(error)),
      ),
      loading: () => renderLoading(),
    );
  }

  Widget renderLoading() {
    return Skeletonizer(
      child: Chip(
        avatar: const Icon(Icons.language),
        label: Text(roomId),
      ),
    );
  }

  Widget renderSpaceChip(BuildContext context, String joinRule) {
    IconData icon = Icons.lock;
    String label = L10n.of(context).private;
    switch (joinRule) {
      case 'public':
        icon = Icons.language;
        label = L10n.of(context).public;
        break;
      case 'restricted':
        icon = Atlas.users;
        label = L10n.of(context).limited;
      case 'invite':
        break;
    }
    return Chip(
      avatar: Icon(
        icon,
        color: Theme.of(context).colorScheme.neutral6,
      ),
      label: Text(label),
    );
  }
}
