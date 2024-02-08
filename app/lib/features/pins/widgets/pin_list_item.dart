import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:go_router/go_router.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PinListItemById extends ConsumerWidget {
  final String pinId;
  final bool showSpace;
  const PinListItemById(
      {required this.pinId, this.showSpace = false, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pin = ref.watch(pinProvider(pinId));
    return pin.when(
      data: (acterPin) => PinListItem(
        pin: acterPin,
        showSpace: showSpace,
      ),
      error: (err, st) => Text('Error loading pin ${err.toString()}'),
      loading: () => const Skeletonizer(child: SizedBox()),
    );
  }
}

class PinListItem extends ConsumerStatefulWidget {
  final ActerPin pin;
  final bool showSpace;
  const PinListItem({
    super.key,
    required this.pin,
    this.showSpace = false,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PinListItemState();
}

class _PinListItemState extends ConsumerState<PinListItem> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final pin = widget.pin;
    final pinId = pin.eventIdStr();
    final isLink = pin.isLink();
    final spaceId = pin.roomIdStr();

    Future<void> openItem() async {
      await context.pushNamed(
        Routes.pin.name,
        pathParameters: {'pinId': pinId},
      );
    }

    Future<void> onTap() async {
      if (isLink) {
        final target = pin.url()!;
        await openLink(target, context);
      } else {
        await openItem();
      }
    }

    return InkWell(
      onTap: onTap,
      onLongPress: openItem,
      child: Card(
        child: ListTile(
          key: Key(pin.eventIdStr()), // FIXME: causes crashes in ffigen
          leading: Icon(isLink ? Atlas.link_chain_thin : Atlas.document_thin),
          title: Text(
            pin.title(),
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
          titleTextStyle: Theme.of(context).textTheme.titleSmall,
          subtitle: widget.showSpace
              ? Wrap(
                  alignment: WrapAlignment.start,
                  children: [SpaceChip(spaceId: spaceId)],
                )
              : null,
          onTap: onTap,
          trailing: IconButton(
            icon: isLink
                ? const Icon(Icons.open_in_full_sharp)
                : const Icon(Icons.chevron_right_sharp),
            onPressed: openItem,
          ),
        ),
      ),
    );
  }
}
