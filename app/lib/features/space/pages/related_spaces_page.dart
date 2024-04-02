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
import 'package:flutter_gen/gen_l10n/l10n.dart';

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
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SpaceHeader(spaceIdOrAlias: spaceIdOrAlias),
          ),
          spaces.when(
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
            error: (error, stack) => SliverToBoxAdapter(
              child: Center(
                child: Text(L10n.of(context).loadingFailed(error)),
              ),
            ),
            loading: () => SliverToBoxAdapter(
              child: Center(
                child: Text(L10n.of(context).loading),
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
          title: L10n.of(context).noConnectedSpaces,
          subtitle: L10n.of(context).inConnectedSpaces,
          image: 'assets/images/empty_space.svg',
          primaryButton: canLinkSpace
              ? ElevatedButton(
                  onPressed: () => context.pushNamed(
                    Routes.createSpace.name,
                    queryParameters: {
                      'parentSpaceId': spaceIdOrAlias,
                    },
                  ),
                  child: Text(L10n.of(context).createNewSpace),
                )
              : null,
        ),
      ),
    );
  }
}
