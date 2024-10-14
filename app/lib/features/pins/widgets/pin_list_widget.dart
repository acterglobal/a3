import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_list_item_widget.dart';
import 'package:acter/features/pins/widgets/pin_list_skeleton.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::pins-list');

class PinListWidget extends ConsumerWidget {
  final String? spaceId;
  final String? searchValue;
  final int? limit;
  final bool showSectionHeader;
  final VoidCallback? onClickSectionHeader;
  final bool shrinkWrap;
  final Widget emptyState;

  const PinListWidget({
    super.key,
    this.limit,
    this.spaceId,
    this.searchValue,
    this.showSectionHeader = false,
    this.onClickSectionHeader,
    this.shrinkWrap = true,
    this.emptyState = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinsLoader = ref.watch(
      pinListSearchProvider((spaceId: spaceId, searchText: searchValue)),
    );

    return pinsLoader.when(
      data: (pinList) => buildPinSectionUI(context, pinList),
      error: (e, s) {
        _log.severe('Failed to load pins', e, s);
        return Center(child: Text(L10n.of(context).loadingFailed(e)));
      },
      loading: () => const PinListSkeleton(),
    );
  }

  Widget buildPinSectionUI(BuildContext context, List<ActerPin> pinList) {
    if (pinList.isEmpty) return emptyState;

    final count = (limit ?? pinList.length).clamp(0, pinList.length);
    return showSectionHeader
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SectionHeader(
                title: L10n.of(context).pins,
                isShowSeeAllButton: count < pinList.length,
                onTapSeeAll: () => onClickSectionHeader == null
                    ? null
                    : onClickSectionHeader!(),
              ),
              pinListUI(pinList, count),
            ],
          )
        : pinListUI(pinList, count);
  }

  Widget pinListUI(List<ActerPin> pinList, int count) {
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      itemCount: count,
      padding: EdgeInsets.zero,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemBuilder: (context, index) {
        return PinListItemWidget(
          pinId: pinList[index].eventIdStr(),
          showSpace: spaceId == null,
        );
      },
    );
  }
}
