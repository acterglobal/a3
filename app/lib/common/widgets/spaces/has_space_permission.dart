import 'package:acter/common/providers/room_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HasSpacePermission extends ConsumerWidget {
  final String spaceId;
  final String permission;
  final Widget child;
  final Widget? fallback;

  const HasSpacePermission({
    super.key,
    required this.spaceId,
    required this.permission,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherwise = fallback ?? const SizedBox.shrink();
    return ref.watch(roomMembershipProvider(spaceId)).when(
          data: (membership) =>
              membership?.canString(permission) == true ? child : otherwise,
          error: (e, s) => otherwise,
          loading: () => otherwise,
        );
  }
}
