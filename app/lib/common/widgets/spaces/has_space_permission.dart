import 'package:acter/common/providers/space_providers.dart';
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
    return ref.watch(spaceMembershipProvider(spaceId)).when(
          data: (membership) =>
              (membership != null && membership.canString(permission))
                  ? child
                  : otherwise,
          error: (e, s) => otherwise,
          loading: () => otherwise,
        );
  }
}
