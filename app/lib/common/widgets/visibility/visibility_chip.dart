import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
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
        return renderSpace(context, space);
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

  Widget renderSpace(BuildContext context, Space space) {
    return Chip(
      avatar: Icon(
        space.isPublic() ? Icons.language : Icons.lock,
        color: Theme.of(context).colorScheme.neutral6,
      ),
      label: Text(
        space.isPublic() ? L10n.of(context).public : L10n.of(context).private,
      ),
    );
  }
}
