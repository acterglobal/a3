import 'package:acter/common/providers/room_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
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
        icon: const Icon(Atlas.plus_circle_thin),
        iconSize: 28,
        color: Theme.of(context).colorScheme.surface,
        onPressed: onPressed,
      ),
    );
  }
}
