import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_list_item_widget.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::space::sections::pins');

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
    final lang = L10n.of(context);
    final pinsLoader = ref.watch(pinListProvider(spaceId));
    return pinsLoader.when(
      data: (pins) => buildPinsSectionUI(context, pins),
      error: (e, s) {
        _log.severe('Failed to load pins in space', e, s);
        return Center(
          child: Text(lang.loadingFailed(e)),
        );
      },
      loading: () => Center(
        child: Text(lang.loading),
      ),
    );
  }

  Widget buildPinsSectionUI(BuildContext context, List<ActerPin> pins) {
    final hasMore = pins.length > limit;
    final count = hasMore ? limit : pins.length;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: L10n.of(context).pins,
          isShowSeeAllButton: hasMore,
          onTapSeeAll: () => context.pushNamed(
            Routes.spacePins.name,
            pathParameters: {'spaceId': spaceId},
          ),
        ),
        pinsListUI(pins, count),
      ],
    );
  }

  Widget pinsListUI(List<ActerPin> pins, int count) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: count,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return PinListItemWidget(pinId: pins[index].eventIdStr());
      },
    );
  }
}
