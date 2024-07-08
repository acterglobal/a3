import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/add_button_with_can_permission.dart';
import 'package:acter/common/widgets/plus_icon_widget.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_list_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

class PinsListPage extends ConsumerWidget {
  final String? spaceId;

  const PinsListPage({
    super.key,
    this.spaceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AsyncValue<List<ActerPin>> pinList;
    String spaceName = '';

    //All pins list
    if (spaceId == null) {
      pinList = ref.watch(pinsProvider);
    }
    //Space pins list
    else {
      spaceName =
          ref.watch(roomDisplayNameProvider(spaceId!)).valueOrNull ?? '';
      final space = ref.watch(spaceProvider(spaceId!)).requireValue;
      pinList = ref.watch(spacePinsProvider(space));
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(L10n.of(context).pins),
            if (spaceName.isNotEmpty)
              Text(
                '($spaceName)',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
          ],
        ),
        actions: [
          if (spaceId == null)
            PlusIconWidget(
              onPressed: () => context.pushNamed(Routes.actionAddPin.name),
            )
          else
            AddButtonWithCanPermission(
              roomId: spaceId!,
              canString: 'CanPostPin',
              onPressed: () => context.pushNamed(
                Routes.actionAddPin.name,
                queryParameters: {'spaceId': spaceId},
              ),
            ),
        ],
      ),
      body: pinList.when(
        data: (pins) => pinsListUI(context, pins),
        error: (error, stack) =>
            Center(child: Text(L10n.of(context).loadingFailed(error))),
        loading: () => Center(
          child: Text(L10n.of(context).loading),
        ),
      ),
    );
  }

  Widget pinsListUI(BuildContext context, List<ActerPin> pins) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: SearchBar(
              leading: const Icon(Atlas.magnifying_glass),
              hintText: L10n.of(context).search,
              hintStyle: WidgetStateProperty.all(
                Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
          ListView.builder(
            itemCount: pins.length,
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return PinListItemById(pinId: pins[index].eventIdStr());
            },
          ),
        ],
      ),
    );
  }
}
