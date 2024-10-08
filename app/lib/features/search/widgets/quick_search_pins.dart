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

final _log = Logger('a3::quick_search::pins');

class QuickSearchPins extends ConsumerWidget {
  final int limit;

  const QuickSearchPins({
    super.key,
    this.limit = 3,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinsLoader = ref.watch(pinListProvider(null));

    return pinsLoader.when(
      data: (pinList) => buildPinSectionUI(context, pinList),
      error: (e, s) {
        _log.severe('Failed to load pins', e, s);
        return Center(
          child: Text(L10n.of(context).loadingFailed(e)),
        );
      },
      loading: () => Center(
        child: Text(L10n.of(context).loading),
      ),
    );
  }

  Widget buildPinSectionUI(BuildContext context, List<ActerPin> pinList) {
    final hasMore = pinList.length > limit;
    final count = hasMore ? limit : pinList.length;
    return pinList.isEmpty
        ? const SizedBox.shrink()
        : Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: L10n.of(context).pins,
                isShowSeeAllButton: hasMore,
                onTapSeeAll: () => context.pushNamed(Routes.pins.name),
              ),
              pinListUI(pinList, count),
            ],
          );
  }

  Widget pinListUI(List<ActerPin> pinList, int count) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: count,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return PinListItemWidget(
          pinId: pinList[index].eventIdStr(),
          showSpace: true,
        );
      },
    );
  }
}
