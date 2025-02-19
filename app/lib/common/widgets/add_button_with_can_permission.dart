import 'package:acter/common/extensions/options.dart';
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
    return canString.map((key) {
          //Show add button if there is at lease one space where user can post
          final canDoLoader = ref.watch(hasSpaceWithPermissionProvider(key));
          var canAdd = canDoLoader.valueOrNull ?? false;

          //If space id is given then check with specific space permission
          spaceId.map((val) {
            final membership =
                ref.watch(roomMembershipProvider(val)).valueOrNull;
            canAdd = membership?.canString(key) == true;
          });

          return canAdd ? _buildIconButton(context) : const SizedBox.shrink();
        }) ??
        //Show add button if nothing to check with can permission
        _buildIconButton(context);
  }

  Widget _buildIconButton(BuildContext context) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          borderRadius: const BorderRadius.all(Radius.circular(100)),
        ),
        child: const Icon(Icons.add),
      ),
      color: Theme.of(context).colorScheme.surface,
      onPressed: onPressed,
    );
  }
}
