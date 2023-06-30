import 'dart:core';
import 'dart:math';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/pins/widgets/pin_list_item.dart';
import 'package:acter/features/space/providers/pins_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';

class SpacePinsPage extends ConsumerWidget {
  final String spaceIdOrAlias;
  const SpacePinsPage({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(spaceProvider(spaceIdOrAlias)).requireValue;
    final pins = ref.watch(spacePinsProvider(space));
    // get platform of context.
    return Padding(
      padding: const EdgeInsets.all(20),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Pins',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Atlas.plus_circle_thin,
                    color: Theme.of(context).colorScheme.neutral5,
                  ),
                  iconSize: 28,
                  color: Theme.of(context).colorScheme.surface,
                  onPressed: () => customMsgSnackbar(
                    context,
                    'Adding Pins not implemented yet',
                  ),
                ),
              ],
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
                  childAspectRatio: 6,
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
