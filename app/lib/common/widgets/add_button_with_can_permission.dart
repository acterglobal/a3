import 'package:acter/common/providers/room_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddButtonWithCanPermission extends ConsumerWidget {
  final String canString;
  final String roomId;
  final VoidCallback onPressed;

  const AddButtonWithCanPermission({
    super.key,
    required this.canString,
    required this.roomId,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(roomMembershipProvider(roomId));
    bool canAdd = membership.requireValue!.canString(canString);

    return Visibility(
      visible: canAdd,
      child: IconButton(
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
      ),
    );
  }
}
