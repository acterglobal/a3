import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter/common/controllers/client_controller.dart';
import 'package:acter/common/models/profile_data.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/controllers/spaces_controller.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
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
      final space = await client.getSpace(related.roomId().toString());
      if (space == null) {
      } else {
        spaces.add(space);
      }
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
      child: Column(
        children: [
          const ListTile(title: Text('Related Spaces')),
          ...spaces.when(
            data: (spaces) => spaces.map(
              (space) {
                final roomId = space.getRoomId();
                final profile = ref.watch(spaceProfileDataProvider(space));
                return OutlinedButton(
                  onPressed: () {
                    context.go('/$roomId');
                  },
                  child: profile.when(
                    data: (profile) => ListTile(
                      title: Text(profile.displayName),
                      leading: profile.avatar != null
                          ? CircleAvatar(
                              foregroundImage: MemoryImage(
                                profile.avatar!,
                              ),
                              radius: 24,
                            )
                          : SvgPicture.asset(
                              'assets/icon/acter.svg',
                              height: 24,
                              width: 24,
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
                  ),
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
