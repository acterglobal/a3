import 'dart:core';
import 'dart:math';

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/widgets/default_page_header.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/features/pins/widgets/pin_list_item.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';

class PinsPage extends ConsumerWidget {
  const PinsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ignore: unused_local_variable
    final account = ref.watch(accountProfileProvider);
    final pins = ref.watch(pinsProvider);
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          PageHeaderWidget(
            title: 'Pins',
            sectionColor: Colors.blue.shade200,
            actions: [
              IconButton(
                icon: const Icon(Atlas.funnel_sort_thin),
                onPressed: () {
                  customMsgSnackbar(
                    context,
                    'Pin filtering not yet implemented',
                  );
                },
              ),
            ],
            expandedContent: const Text(
              'Pinned items from all the Spaces you are part of',
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
                  return PinListItem(
                    pin: pin,
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
