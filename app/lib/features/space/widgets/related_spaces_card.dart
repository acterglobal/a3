import 'dart:core';

import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/spaces/space_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                  Routes.spaceRelatedSpaces.name,
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
                (space) => SpaceCard.small(
                  space: space,
                  titleTextStyle: Theme.of(context).textTheme.bodySmall,
                  subtitleTextStyle: Theme.of(context).textTheme.bodySmall,
                  showParent: false,
                ),
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
