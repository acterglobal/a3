import 'dart:math';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/add_button_with_can_permission.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_list_item.dart';
import 'package:acter/features/space/widgets/space_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SpacePinsPage extends ConsumerWidget {
  final String spaceIdOrAlias;

  const SpacePinsPage({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(spaceProvider(spaceIdOrAlias)).requireValue;
    final pins = ref.watch(spacePinsProvider(space));

    // get platform of context.
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: primaryGradient),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SpaceHeader(
              spaceIdOrAlias: spaceIdOrAlias,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      L10n.of(context).pins,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  AddButtonWithCanPermission(
                    roomId: spaceIdOrAlias,
                    canString: 'CanPostPin',
                    onPressed: () => context.pushNamed(
                      Routes.actionAddPin.name,
                      queryParameters: {'spaceId': spaceIdOrAlias},
                    ),
                  ),
                ],
              ),
            ),
          ),
          pins.when(
            data: (pins) {
              final size = MediaQuery.of(context).size;
              final widthCount = (size.width ~/ 600).toInt();
              const int minCount = 2;
              if (pins.isEmpty) {
                final membership =
                    ref.watch(roomMembershipProvider(spaceIdOrAlias));
                bool canAdd = membership.requireValue!.canString('CanPostPin');
                return SliverToBoxAdapter(
                  child: Center(
                    heightFactor: 1,
                    child: EmptyState(
                      title: L10n.of(context).noPinsAvailableYet,
                      subtitle: L10n.of(context).noPinsAvailableDescription,
                      image: 'assets/images/empty_pin.svg',
                      primaryButton: canAdd
                          ? ActerPrimaryActionButton(
                              onPressed: () => context.pushNamed(
                                Routes.actionAddPin.name,
                                queryParameters: {'spaceId': spaceIdOrAlias},
                              ),
                              child: Text(L10n.of(context).sharePin),
                            )
                          : null,
                    ),
                  ),
                );
              }
              return SliverToBoxAdapter(
                child: StaggeredGrid.count(
                  crossAxisCount: max(1, min(widthCount, minCount)),
                  children: <Widget>[
                    for (var pin in pins)
                      PinListItemById(pinId: pin.eventIdStr()),
                  ],
                ),
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
}
