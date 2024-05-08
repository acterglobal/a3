import 'dart:math';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/space/widgets/related_spaces/helpers.dart';
import 'package:acter/features/space/widgets/space_header.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SubSpacesPage extends ConsumerWidget {
  static const moreOptionKey = Key('related-spaces-more-actions');
  static const createSubspaceKey = Key('related-spaces-more-create-subspace');
  static const linkSubspaceKey = Key('related-spaces-more-link-subspace');

  final String spaceIdOrAlias;

  const SubSpacesPage({super.key, required this.spaceIdOrAlias});

  Widget _renderTools(
    BuildContext context,
  ) {
    return PopupMenuButton(
      icon: Icon(
        Atlas.plus_circle,
        key: moreOptionKey,
        color: Theme.of(context).colorScheme.neutral5,
      ),
      iconSize: 28,
      color: Theme.of(context).colorScheme.surface,
      itemBuilder: (BuildContext context) => <PopupMenuEntry>[
        PopupMenuItem(
          key: createSubspaceKey,
          onTap: () => context.pushNamed(
            Routes.createSpace.name,
            queryParameters: {'parentSpaceId': spaceIdOrAlias},
          ),
          child: Row(
            children: <Widget>[
              Text(L10n.of(context).createSubspace),
              const Spacer(),
              const Icon(Atlas.connection),
            ],
          ),
        ),
        PopupMenuItem(
          key: linkSubspaceKey,
          onTap: () => context.pushNamed(
            Routes.linkSubspace.name,
            pathParameters: {'spaceId': spaceIdOrAlias},
          ),
          child: Row(
            children: <Widget>[
              Text(L10n.of(context).linkExistingSpace),
              const Spacer(),
              const Icon(Atlas.connection),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () => context.pushNamed(
            Routes.linkRecommended.name,
            pathParameters: {'spaceId': spaceIdOrAlias},
          ),
          child: Row(
            children: [
              Text(L10n.of(context).recommendedSpaces),
              const Spacer(),
              const Icon(Atlas.plus_circle),
            ],
          ),
        ),
      ],
    );
  }

  Widget? titleBuilder(BuildContext context, bool canLink) {
    if (canLink) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [_renderTools(context)],
      );
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(spaceRelationsOverviewProvider(spaceIdOrAlias));
    final widthCount = (MediaQuery.of(context).size.width ~/ 300).toInt();
    const int minCount = 3;
    final crossAxisCount = max(1, min(widthCount, minCount));
    // get platform of context.
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: primaryGradient),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SpaceHeader(spaceIdOrAlias: spaceIdOrAlias),
            spaces.when(
              data: (spaces) {
                return renderSubSpaces(
                      context,
                      spaceIdOrAlias,
                      spaces,
                      crossAxisCount: crossAxisCount,
                      titleBuilder: () => titleBuilder(
                        context,
                        spaces.membership?.canString('CanLinkSpaces') ?? false,
                      ),
                    ) ??
                    renderFallback(
                      context,
                      spaces.membership?.canString('CanLinkSpaces') ?? false,
                    );
              },
              error: (error, stack) => Center(
                child: Text(L10n.of(context).loadingFailed(error)),
              ),
              loading: () => Center(
                child: Text(L10n.of(context).loading),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget renderFallback(BuildContext context, bool canLinkSpace) {
    return Center(
      heightFactor: 1,
      child: EmptyState(
        title: L10n.of(context).noConnectedSpaces,
        subtitle: L10n.of(context).inConnectedSpaces,
        image: 'assets/images/empty_space.svg',
        primaryButton: canLinkSpace
            ? ActerPrimaryActionButton(
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
    );
  }
}
