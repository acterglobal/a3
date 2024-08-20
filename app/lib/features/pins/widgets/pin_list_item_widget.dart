import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/space_name_widget.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_icon.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::pins::pin_item');

class PinListItemWidget extends ConsumerWidget {
  final String pinId;
  final bool showSpace;

  const PinListItemWidget({
    required this.pinId,
    this.showSpace = false,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinData = ref.watch(pinProvider(pinId));
    return pinData.when(
      data: (pin) => buildPinItemUI(context, pin),
      error: (e, s) {
        _log.severe('Failed to load pin', e, s);
        return Text(L10n.of(context).errorLoadingPin(e));
      },
      loading: () => const Skeletonizer(
        child: SizedBox(height: 100, width: 100),
      ),
    );
  }

  Widget buildPinItemUI(BuildContext context, ActerPin pin) {
    return Card(
      child: ListTile(
        onTap: () => context.pushNamed(
          Routes.pin.name,
          pathParameters: {'pinId': pinId},
        ),
        leading: const PinIcon(),
        title: Text(pin.title(), overflow: TextOverflow.ellipsis),
        subtitle: showSpace
            ? SpaceNameWidget(spaceId: pin.roomIdStr(), isShowBrackets: false)
            : null,
      ),
    );
  }
}
