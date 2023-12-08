import 'dart:core';
import 'dart:math';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/add_button_with_can_permission.dart';
import 'package:acter/common/widgets/default_button.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_list_item.dart';
import 'package:acter/features/space/widgets/space_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/widgets/error_widget.dart';

class SpacePinsPage extends ConsumerWidget {
  final String spaceIdOrAlias;

  const SpacePinsPage({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(spaceProvider(spaceIdOrAlias)).requireValue;
    final pins = ref.watch(spacePinsProvider(space));

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
                return  SliverToBoxAdapter(
                  child: Center(
                    heightFactor: 1,
                    child: ErrorWidgetTemplate(
                      title: 'No pins available yet',
                      subtitle:
                          'Share important resources with your community such as documents or links so everyone is updated.',
                      image: 'assets/images/empty_pin.png',
                      button: DefaultButton(
                        onPressed: () {},
                        title: 'Share Pin',
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.success,
                          disabledBackgroundColor: Theme.of(context)
                              .colorScheme
                              .success
                              .withOpacity(0.5),
                        ),
                      ),
                    ),
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
  }
}
