import 'package:acter/common/providers/room_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef CanPermissionParam = ({String spaceId, String canString});

class AddButtonWithCanPermission extends ConsumerWidget {
  final VoidCallback onPressed;
  final CanPermissionParam? canPermissionParam;

  const AddButtonWithCanPermission({
    super.key,
    required this.onPressed,
    this.canPermissionParam,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (canPermissionParam == null) return _buildIconButton(context);

    final membership =
        ref.watch(roomMembershipProvider(canPermissionParam!.spaceId));

    bool canAdd = membership.requireValue!.canString(
      canPermissionParam!.canString,
    );

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
