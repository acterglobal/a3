import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class InviteToSpaceDialog extends ConsumerWidget {
  final String spaceId;
  const InviteToSpaceDialog({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(briefSpaceItemWithMembershipProvider(spaceId));
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 400),
      child: Scaffold(
          appBar: space.when(
            data: (space) => AppBar(
              title: Text(
                'Invite Users to ${space.spaceProfileData.displayName}',
              ),
            ),
            error: (error, stackTrace) => AppBar(title: Text('Error: $error')),
            loading: () => AppBar(
              title: const Text('Invite user'),
            ),
          ),
          // title: const Text('Invite User to')),
          body: const Center(
            child: Text('public search box'),
          )),
    );
  }
}
