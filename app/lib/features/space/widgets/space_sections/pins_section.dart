import 'dart:math';

import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_list_item.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

class PinsSection extends ConsumerWidget {
  final String spaceId;
  final int limit;

  const PinsSection({
    super.key,
    required this.spaceId,
    this.limit = 3,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinList = ref.watch(pinListProvider(spaceId));
    return pinList.when(
      data: (pins) => buildPinsSectionUI(context, pins),
      error: (error, stack) =>
          Center(child: Text(L10n.of(context).loadingFailed(error))),
      loading: () => Center(
        child: Text(L10n.of(context).loading),
      ),
    );
  }

  Widget buildPinsSectionUI(BuildContext context, List<ActerPin> pins) {
    int pinsLimit = (pins.length > limit) ? limit : pins.length;
    bool isShowSeeAllButton = pins.length > pinsLimit;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: L10n.of(context).pins,
          isShowSeeAllButton: isShowSeeAllButton,
          onTapSeeAll: () => context.pushNamed(
            Routes.spacePins.name,
            pathParameters: {'spaceId': spaceId},
          ),
        ),
        pinsListUI(context, pins, pinsLimit),
      ],
    );
  }

  Widget pinsListUI(BuildContext context, List<ActerPin> pins, int pinsLimit) {
    final size = MediaQuery.of(context).size;
    final widthCount = (size.width ~/ 500).toInt();
    const int minCount = 2;

    return StaggeredGrid.count(
      crossAxisCount: max(1, min(widthCount, minCount)),
      children: [
        for (var pin in pins) PinListItemById(pinId: pin.eventIdStr()),
      ],
    );
  }
}
