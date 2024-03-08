import 'dart:math';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/space/widgets/relatest_spaces.dart';
import 'package:acter/features/space/widgets/space_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RelatedSpacesPage extends ConsumerWidget {
  final String spaceIdOrAlias;

  const RelatedSpacesPage({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(spaceRelationsOverviewProvider(spaceIdOrAlias));
    final widthCount = (MediaQuery.of(context).size.width ~/ 300).toInt();
    const int minCount = 3;
    final crossAxisCount = max(1, min(widthCount, minCount));
    // get platform of context.
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: primaryGradient),
      child: Column(
        children: [
          SpaceHeader(spaceIdOrAlias: spaceIdOrAlias),
          Expanded(
            child: spaces.when(
              data: (spaces) {
                final canLinkSpace =
                    spaces.membership?.canString('CanLinkSpaces') ?? false;
                return RelatedSpaces(
                  spaceIdOrAlias: spaceIdOrAlias,
                  spaces: spaces,
                  crossAxisCount: crossAxisCount,
                  fallback: renderFallback(context, canLinkSpace),
                );
              },
              error: (error, stack) => Center(
                child: Text('Loading failed: $error'),
              ),
              loading: () => const Center(
                child: Text('Loading'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget renderFallback(BuildContext context, bool canLinkSpace) {
    return SliverToBoxAdapter(
      child: Center(
        heightFactor: 1,
        child: EmptyState(
          title: 'No connected spaces',
          subtitle:
              'In connected spaces, you can focus on specific actions or campaigns of your working groups and start organizing.',
          image: 'assets/images/empty_space.svg',
          primaryButton: canLinkSpace
              ? ElevatedButton(
                  onPressed: () => context.pushNamed(
                    Routes.createSpace.name,
                    queryParameters: {
                      'parentSpaceId': spaceIdOrAlias,
                    },
                  ),
                  child: const Text('Create New Spaces'),
                )
              : null,
        ),
      ),
    );
  }
}
