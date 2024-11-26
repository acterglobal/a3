import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/acter_icon_picker/acter_icon_widget.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/color_data.dart';
import 'package:acter/common/widgets/space_name_widget.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::pins::list_item');

class PinListItemWidget extends ConsumerWidget {
  final String pinId;
  final bool showSpace;
  final bool showPinIndication;
  final Function(String)? onTaPinItem;

  const PinListItemWidget({
    required this.pinId,
    this.showSpace = false,
    this.showPinIndication = false,
    this.onTaPinItem,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinData = ref.watch(pinProvider(pinId));
    return pinData.when(
      data: (pin) => buildPinItemUI(context, pin),
      error: (e, s) {
        _log.severe('Failed to load pin', e, s);
        return Text(L10n.of(context).loadingFailed(e));
      },
      loading: () => const Skeletonizer(
        child: SizedBox(height: 100, width: 100),
      ),
    );
  }

  Widget buildPinItemUI(BuildContext context, ActerPin pin) {
    return Card(
      child: ListTile(
        onTap: () {
          final pinId = pin.eventIdStr();
          if (onTaPinItem == null) {
            context.pushNamed(
              Routes.pin.name,
              pathParameters: {'pinId': pinId},
            );
          } else {
            onTaPinItem!(pinId);
          }
        },
        leading: ActerIconWidget(
          iconSize: 30,
          color: convertColor(
            pin.display()?.color(),
            iconPickerColors[0],
          ),
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
        subtitle: showSpace
            ? SpaceNameWidget(spaceId: pin.roomIdStr(), isShowBrackets: false)
            : null,
      ),
    );
  }
}
