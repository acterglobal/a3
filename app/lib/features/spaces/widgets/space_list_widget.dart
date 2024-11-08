import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/widgets/room/room_card.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpaceListWidget extends ConsumerWidget {
  final ProviderBase<List<Space>> spaceListProvider;
  final int? limit;
  final bool showSectionHeader;
  final VoidCallback? onClickSectionHeader;
  final String? sectionHeaderTitle;
  final bool? isShowSeeAllButton;
  final bool shrinkWrap;
  final Widget emptyState;

  const SpaceListWidget({
    super.key,
    required this.spaceListProvider,
    this.limit,
    this.showSectionHeader = false,
    this.onClickSectionHeader,
    this.sectionHeaderTitle,
    this.isShowSeeAllButton,
    this.shrinkWrap = true,
    this.emptyState = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceList = ref.watch(spaceListProvider);
    if (spaceList.isEmpty) return emptyState;

    final count = (limit ?? spaceList.length).clamp(0, spaceList.length);
    return showSectionHeader
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SectionHeader(
                title: sectionHeaderTitle ?? L10n.of(context).spaces,
                isShowSeeAllButton:
                    isShowSeeAllButton ?? count < spaceList.length,
                onTapSeeAll: onClickSectionHeader.map((cb) => () => cb()),
              ),
              spaceListUI(spaceList, count),
            ],
          )
        : spaceListUI(spaceList, count);
  }

  Widget spaceListUI(List<Space> spaceList, int count) {
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      itemCount: count,
      padding: EdgeInsets.zero,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemBuilder: (context, index) {
        return RoomCard(roomId: spaceList[index].getRoomIdStr());
      },
    );
  }
}
