import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter/common/controllers/client_controller.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/controllers/spaces_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:core';

final relatedSpacesProvider =
    FutureProvider.family<List<Space>, String>((ref, spaceId) async {
  final client = ref.watch(clientProvider)!;
  final relatedSpaces = ref.watch(spaceRelationsProvider(spaceId)).requireValue;
  print("related found");
  final spaces = [];
  for (final related in relatedSpaces.children()) {
    print("child 1");
    if (related.targetType().tag != RelationTargetTypeTag.ChatRoom) {
      final roomId = related.roomId().toString();
      print("Loading $roomId");
      final room = await client.getSpace(related.roomId().toString());
      print("Space found.");
      if (room == null) {
        print("Related room unknown");
      } else {
        spaces.add(room);
      }
    }
  }
  print("returning");
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
      child: Column(
        children: [
          const ListTile(title: Text('Related Spaces')),
          ...spaces.when(
            data: (spaces) => spaces.map(
              (space) {
                final roomId = space.getRoomId();
                return OutlinedButton(
                  onPressed: () {
                    context.go('/$roomId');
                  },
                  child: Text(space.getRoomId()),
                );
              },
            ),
            error: (error, stack) => [Text('Loading spaces failed: $error')],
            loading: () => [const Text('Loading')],
          )
        ],
      ),
    );
  }
}
