import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddButtonWithCanPermission extends ConsumerWidget {
  final VoidCallback onPressed;
  final String? spaceId;
  final String? canString;

  const AddButtonWithCanPermission({
    super.key,
    required this.onPressed,
    this.spaceId,
    this.canString,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //Show add button if nothing to check with can permission
    if (canString == null) return _buildIconButton(context);

    //Show add button if there is at lease one space where user can post
    final canDoLoader = ref.watch(hasSpaceWithPermissionProvider(canString!));
    var canAdd = canDoLoader.valueOrNull ?? false;

    //If space id is given then check with specific space permission
    if (spaceId != null) {
      final membership =
          ref.watch(roomMembershipProvider(spaceId!)).valueOrNull;
      canAdd = membership?.canString(canString!) == true;
    }

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
