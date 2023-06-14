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
    final spaceItems = ref.watch(spaceItemsProvider);
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
          ...spaceItems.when(
            data: (items) => [
              ...items
                  .sublist(0, items.length > limit ? limit : items.length)
                  .map(
                (item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      onTap: () => context.go('/${item.roomId}'),
                      title: Text(
                        item.spaceProfileData.displayName ?? item.roomId,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      leading: ActerAvatar(
                        mode: DisplayMode.Space,
                        displayName: item.spaceProfileData.displayName,
                        uniqueId: item.roomId,
                        avatar: item.spaceProfileData.getAvatarImage(),
                        size: 48,
                      ),
                    ),
                  );
                },
              ),
              items.length > limit
                  ? Padding(
                      padding: const EdgeInsets.only(left: 30),
                      child: Text('see all ${items.length} spaces'),
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
