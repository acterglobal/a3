import 'dart:core';
import 'dart:math';

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/widgets/default_page_header.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/features/pins/widgets/pin_list_item.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/themes/app_theme.dart';

class PinsPage extends ConsumerWidget {
  const PinsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ignore: unused_local_variable
    final account = ref.watch(accountProfileProvider);
    final pins = ref.watch(pinsProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.neutral,
      body: CustomScrollView(
        slivers: <Widget>[
          PageHeaderWidget(
            title: 'Pins',
            sectionDecoration: const BoxDecoration(
              gradient: primaryGradient,
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Atlas.plus_circle_thin,
                  color: Theme.of(context).colorScheme.neutral5,
                ),
                iconSize: 28,
                color: Theme.of(context).colorScheme.surface,
                onPressed: () => context.pushNamed(
                  Routes.actionAddPin.name,
                ),
              ),
            ],
            expandedContent: Text(
              'Pinned items from all the Spaces you are part of',
              softWrap: true,
              style: Theme.of(context).textTheme.bodySmall,
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
                  mainAxisExtent: 100,
                ),
                itemBuilder: (context, index) {
                  final pin = pins[index];
                  return PinListItemById(
                    pinId: pin.eventIdStr(),
                    showSpace: true,
                  );
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
