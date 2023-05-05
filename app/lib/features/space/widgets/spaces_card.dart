import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter/features/home/states/client_state.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:core';

final relatedSpacesProvider =
    FutureProvider.family<List<Space>, String>((ref, spaceId) async {
  final client = ref.watch(clientProvider)!;
  final relatedSpaces = ref.watch(spaceRelationsProvider(spaceId)).requireValue;
  final spaces = [];
  for (final related in relatedSpaces.children()) {
    if (related.targetType().tag != RelationTargetTypeTag.ChatRoom) {
      final roomId = related.roomId().toString();
      final space = await client.getSpace(roomId);
      spaces.add(space);
    }
  }
  return List<Space>.from(spaces);
});

class SpacesCard extends ConsumerWidget {
  final String spaceId;
  const SpacesCard({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(relatedSpacesProvider(spaceId));

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Related Spaces',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            ...spaces.when(
              data: (spaces) => spaces.map(
                (space) {
                  final roomId = space.getRoomId().toString();
                  final profile = ref.watch(spaceProfileDataProvider(space));
                  return profile.when(
                    data: (profile) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap: () => context.go('/$roomId'),
                        title: Text(
                          profile.displayName,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        leading: profile.hasAvatar()
                            ? CircleAvatar(
                                foregroundImage: profile.getAvatarImage(),
                                radius: 24,
                              )
                            : SvgPicture.asset(
                                'assets/icon/acter.svg',
                                height: 24,
                                width: 24,
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
              error: (error, stack) => [Text('Loading spaces failed: $error')],
              loading: () => [const Text('Loading')],
            )
          ],
        ),
      ),
    );
  }
}
