import 'dart:math';

import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_page_header.dart';
import 'package:acter/features/pins/widgets/pin_list_item.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show ActerPin;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class PinsPage extends ConsumerWidget {
  const PinsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pins = ref.watch(pinsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.neutral,
      body: CustomScrollView(
        slivers: <Widget>[
          _buildPageHeader(context),
          _buildPinsGrid(context, pins),
        ],
      ),
    );
  }

  // pins section header
  Widget _buildPageHeader(BuildContext context) {
    return PageHeaderWidget(
      title: L10n.of(context).pins,
      sectionDecoration: const BoxDecoration(
        gradient: primaryGradient,
      ),
      actions: [
        // FIXME: only show with hasAnySpacesWithPermission check
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
        L10n.of(context).pinnedItemsFromAllSpaces,
        softWrap: true,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  // pin items builder
  Widget _buildPinsGrid(BuildContext context, AsyncValue<List<ActerPin>> pins) {
    return pins.when(
      data: (pins) {
        final size = MediaQuery.of(context).size;

        final widthCount = (size.width ~/ 600).toInt();
        const int minCount = 2;

        if (pins.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Text(L10n.of(context).thereIsNothingPinnedYet),
            ),
          );
        }

        return SliverToBoxAdapter(
          child: StaggeredGrid.count(
            crossAxisCount: max(1, min(widthCount, minCount)),
            children: <Widget>[
              for (var pin in pins)
                PinListItemById(
                  pinId: pin.eventIdStr(),
                  showSpace: true,
                ),
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
    );
  }
}
