import 'dart:core';
import 'dart:math';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/add_button_with_can_permission.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_list_item.dart';
import 'package:acter/features/space/widgets/space_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SpacePinsPage extends ConsumerWidget {
  final String spaceIdOrAlias;

  const SpacePinsPage({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(spaceProvider(spaceIdOrAlias)).requireValue;
    final pins = ref.watch(spacePinsProvider(space));

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
                      'Pins',
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
              final widthCount =
                  (MediaQuery.of(context).size.width ~/ 600).toInt();
              const int minCount = 2;
              if (pins.isEmpty) {
                return Consumer(
                  builder: (context, ref, child) {
                    final membership =
                        ref.watch(roomMembershipProvider(spaceIdOrAlias));
                    bool canAdd =
                        membership.valueOrNull!.canString('CanPostPin');
                    return SliverToBoxAdapter(
                      child: Center(
                        heightFactor: 1,
                        child: EmptyState(
                          title: 'No pins available yet',
                          subtitle:
                              'Share important resources with your community such as documents or links so everyone is updated.',
                          image: 'assets/images/empty_pin.svg',
                          primaryButton: canAdd
                              ? ElevatedButton(
                                  onPressed: () => context.pushNamed(
                                    Routes.actionAddPin.name,
                                    queryParameters: {
                                      'spaceId': spaceIdOrAlias,
                                    },
                                  ),
                                  child: const Text('Share Pin'),
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                );
              }
              return SliverGrid.builder(
                itemCount: pins.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: max(1, min(widthCount, minCount)),
                  mainAxisExtent: 100,
                ),
                itemBuilder: (context, index) {
                  final pin = pins[index];
                  return PinListItem(pinId: pin.eventIdStr());
                },
              );
            },
            error: (error, stack) => SliverToBoxAdapter(
              child: Center(
                child: Text('Loading failed: $error'),
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Text('Loading'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
