import 'package:acter/router/routes.dart';
import 'package:acter/common/widgets/acter_icon_picker/acter_icon_widget.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/color_data.dart';
import 'package:acter/features/deep_linking/widgets/reference_details_item.dart';
import 'package:acter/common/widgets/space_name_widget.dart';
import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:acter/features/bookmarks/types.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PinListItemWidget extends ConsumerWidget {
  static const pinItemClick = Key('pin_item_click');

  final String pinId;
  final RefDetails? refDetails;
  final bool showSpace;
  final bool showPinIndication;
  final EdgeInsetsGeometry? cardMargin;
  final Function(String)? onTaPinItem;

  const PinListItemWidget({
    required this.pinId,
    this.refDetails,
    this.showSpace = false,
    this.showPinIndication = false,
    this.cardMargin,
    this.onTaPinItem,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pin = ref.watch(pinProvider(pinId)).valueOrNull;
    if (pin != null) {
      return buildPinItemUI(context, ref, pin);
    } else if (refDetails != null) {
      return ReferenceDetailsItem(refDetails: refDetails!);
    } else {
      return const Skeletonizer(child: SizedBox(height: 100, width: 100));
    }
  }

  Widget buildPinItemUI(BuildContext context, WidgetRef ref, ActerPin pin) {
    final isBookmarked = ref.watch(
      isBookmarkedProvider(BookmarkType.forPins(pinId)),
    );
    return Card(
      margin: cardMargin,
      child: Stack(
        children: [
          buildPinItemView(pin, context),
          if (isBookmarked) buildPinBookmarkView(context),
        ],
      ),
    );
  }

  Widget buildPinItemView(ActerPin pin, BuildContext context) {
    return ListTile(
      key: pinItemClick,
      onTap: () {
        final pinId = pin.eventIdStr();
        if (onTaPinItem == null) {
          context.pushNamed(Routes.pin.name, pathParameters: {'pinId': pinId});
        } else {
          onTaPinItem!(pinId);
        }
      },
      leading: ActerIconWidget(
        iconSize: 30,
        color: convertColor(pin.display()?.color(), iconPickerColors[0]),
        icon: ActerIcon.iconForPin(pin.display()?.iconStr()),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(pin.title(), overflow: TextOverflow.ellipsis),
          if (showPinIndication)
            Row(
              children: [
                Icon(Atlas.pin, size: 16),
                SizedBox(width: 6),
                Text(
                  L10n.of(context).pin,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
        ],
      ),
      subtitle:
          showSpace
              ? SpaceNameWidget(spaceId: pin.roomIdStr(), brackets: false)
              : null,
    );
  }

  Widget buildPinBookmarkView(BuildContext context) {
    return Positioned(
      right: 20,
      top: -4,
      child: Icon(
        Icons.bookmark_sharp,
        color: Theme.of(context).unselectedWidgetColor,
        size: 24,
      ),
    );
  }
}
