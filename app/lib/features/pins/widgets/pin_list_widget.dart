import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/features/pins/widgets/pin_list_item_widget.dart';
import 'package:acter/features/pins/widgets/pin_list_skeleton.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::pins::list');

class PinListWidget extends ConsumerWidget {
  final ProviderBase<AsyncValue<List<ActerPin>>> pinListProvider;
  final String? spaceId;
  final String? searchValue;
  final int? limit;
  final bool showSectionHeader;
  final VoidCallback? onClickSectionHeader;
  final Function(String)? onTaPinItem;
  final bool shrinkWrap;
  final Widget emptyState;

  const PinListWidget({
    super.key,
    required this.pinListProvider,
    this.limit,
    this.spaceId,
    this.searchValue,
    this.showSectionHeader = false,
    this.onClickSectionHeader,
    this.onTaPinItem,
    this.shrinkWrap = true,
    this.emptyState = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinsLoader = ref.watch(pinListProvider);

    return pinsLoader.when(
      data: (pinList) => buildPinSectionUI(context, pinList),
      error: (error, stack) => pinListErrorWidget(context, ref, error, stack),
      loading: () => const PinListSkeleton(),
    );
  }

  Widget pinListErrorWidget(
    BuildContext context,
    WidgetRef ref,
    Object error,
    StackTrace stack,
  ) {
    _log.severe('Failed to load pins', error, stack);
    return ErrorPage(
      background: const PinListSkeleton(),
      error: error,
      stack: stack,
      textBuilder: (error, code) => L10n.of(context).loadingFailed(error),
      onRetryTap: () {
        ref.invalidate(pinListProvider);
      },
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
                onTapSeeAll: onClickSectionHeader.map((cb) => () => cb()),
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
          onTaPinItem: onTaPinItem,
        );
      },
    );
  }
}
