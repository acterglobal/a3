import 'package:acter/common/providers/room_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::common::spaces::has_permission');

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
    final hasPermission =
        ref
            .watch(
              roomPermissionProvider((roomId: spaceId, permission: permission)),
            )
            .valueOrNull ==
        true;
    return hasPermission ? child : otherwise;
  }
}
