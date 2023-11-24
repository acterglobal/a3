import 'dart:core';
import 'dart:math';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_list_item.dart';
import 'package:acter/features/space/widgets/space_header.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SpacePinsPage extends ConsumerWidget {
  final String spaceIdOrAlias;

  const SpacePinsPage({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceRelationsOverview =
        ref.watch(spaceRelationsOverviewProvider(spaceIdOrAlias));
    final space = ref.watch(spaceProvider(spaceIdOrAlias)).requireValue;
    final pins = ref.watch(spacePinsProvider(space));

    return spaceRelationsOverview.when(
      data: (spaceData) {
        bool checkPermission(String permission) {
          if (spaceData.membership != null) {
            return spaceData.membership!.canString(permission);
          }
          return false;
        }

        final canPostPin = checkPermission('CanPostPin');

        // get platform of context.
        return DecoratedBox(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
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
                      Visibility(
                        visible: canPostPin,
                        child: IconButton(
                          icon: Icon(
                            Atlas.plus_circle_thin,
                            color: Theme.of(context).colorScheme.neutral5,
                          ),
                          iconSize: 28,
                          color: Theme.of(context).colorScheme.surface,
                          onPressed: () => context.pushNamed(
                            Routes.actionAddPin.name,
                            queryParameters: {'spaceId': spaceIdOrAlias},
                          ),
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
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Text('there is nothing pinned yet'),
                      ),
                    );
                  }
                  return SliverGrid.builder(
                    itemCount: pins.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: max(1, min(widthCount, minCount)),
                      childAspectRatio: 4.0,
                    ),
                    itemBuilder: (context, index) {
                      final pin = pins[index];
                      return PinListItem(pin: pin);
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
      },
      error: (error, stack) => Center(
        child: Text('Loading failed: $error'),
      ),
      loading: () => const Center(
        child: Text('Loading'),
      ),
    );
  }
}
