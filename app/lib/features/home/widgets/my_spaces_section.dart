import 'dart:core';

import 'package:acter/features/space/providers/space_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MySpacesSection extends ConsumerWidget {
  final int limit;

  const MySpacesSection({super.key, required this.limit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // remove nested watches to avoid big memory error on release runtime
    final spaces = ref.watch(spaceItemsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Spaces',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          ...spaces.when(
            data: (spaces) => [
              ...spaces
                  .sublist(0, spaces.length > limit ? limit : spaces.length)
                  .map(
                (space) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: ListTile(
                      onTap: () => context.go('/${space.roomId}'),
                      title: Text(
                        space.spaceProfileData.displayName ?? space.roomId,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      leading: ActerAvatar(
                        mode: DisplayMode.Space,
                        displayName: space.spaceProfileData.displayName,
                        uniqueId: space.roomId,
                        avatar: space.spaceProfileData.getAvatarImage(),
                        size: 48,
                      ),
                    ),
                  );
                },
              ),
              spaces.length > limit
                  ? Padding(
                      padding: const EdgeInsets.only(left: 30),
                      child: Text('see all ${spaces.length} spaces'),
                    ) // FIXME: click and where?
                  : const Text(''),
            ],
            error: (error, stack) => [Text('Loading spaces failed: $error')],
            loading: () => [const Text('Loading')],
          )
        ],
      ),
    );
  }
}
