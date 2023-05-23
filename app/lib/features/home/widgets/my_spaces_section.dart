import 'dart:core';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MySpacesSection extends ConsumerWidget {
  final int limit;

  const MySpacesSection({super.key, required this.limit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(spacesProvider);
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
                  final roomId = space.getRoomId().toString();
                  final profile = ref.watch(spaceProfileDataProvider(space));
                  return profile.when(
                    data: (profile) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: 10,
                      ),
                      child: ListTile(
                        onTap: () => context.go('/$roomId'),
                        title: Text(
                          profile.displayName ?? roomId,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        leading: ActerAvatar(
                          mode: DisplayMode.Space,
                          displayName: profile.displayName,
                          uniqueId: roomId,
                          avatar: profile.getAvatarImage(),
                          size: 48,
                        ),
                      ),
                    ),
                    error: (error, stack) => ListTile(
                      title: Text('Error loading: $roomId'),
                      subtitle: Text('$error'),
                    ),
                    loading: () => ListTile(
                      title: Text(roomId),
                      subtitle: const Text('loading'),
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
