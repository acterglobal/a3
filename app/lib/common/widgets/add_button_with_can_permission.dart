import 'package:acter/common/providers/space_providers.dart';
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
    if (canString == null) return _buildIconButton(context);
    final canAdd =
        ref.watch(hasSpaceWithPermissionProvider(canString!)).valueOrNull ??
            false;

    return canAdd ? _buildIconButton(context) : const SizedBox.shrink();
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
