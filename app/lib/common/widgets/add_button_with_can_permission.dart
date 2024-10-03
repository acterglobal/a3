import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddButtonWithCanPermission extends ConsumerWidget {
  final VoidCallback onPressed;
  final String? canString;

  const AddButtonWithCanPermission({
    super.key,
    required this.onPressed,
    this.canString,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return canString.let((p0) {
          final canDoLoader = ref.watch(hasSpaceWithPermissionProvider(p0));
          return canDoLoader.valueOrNull == true
              ? _buildIconButton(context)
              : const SizedBox.shrink();
        }) ??
        _buildIconButton(context);
  }

  Widget _buildIconButton(BuildContext context) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
          borderRadius: const BorderRadius.all(Radius.circular(100)),
        ),
        child: const Icon(Icons.add),
      ),
      color: Theme.of(context).colorScheme.surface,
      onPressed: onPressed,
    );
  }
}
