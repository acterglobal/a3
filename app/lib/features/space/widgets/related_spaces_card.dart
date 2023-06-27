import 'dart:core';

import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/space/providers/space_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class RelatedSpacesCard extends ConsumerWidget {
  final String spaceId;

  const RelatedSpacesCard({super.key, required this.spaceId});

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
            InkWell(
              onTap: () {
                context.pushNamed(
                  Routes.relatedSpaces.name,
                  pathParameters: {'spaceId': spaceId},
                );
              },
              child: Text(
                'Related Spaces',
                style: Theme.of(context).textTheme.titleMedium,
              ),
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
                      child: Column(
                        children: [
                          ListTile(
                            onTap: () => context.go('/$roomId'),
                            title: Text(
                              profile.displayName ?? roomId,
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
                        ],
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
            ),
          ],
        ),
      ),
    );
  }
}
