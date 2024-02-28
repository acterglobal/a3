import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:go_router/go_router.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PinListItemById extends ConsumerWidget {
  final String pinId;
  final bool showSpace;
  const PinListItemById({
    required this.pinId,
    this.showSpace = false,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pin = ref.watch(pinProvider(pinId));
    return pin.when(
      data: (acterPin) => PinListItem(
        key: Key('pin-list-item-$pinId'),
        pin: acterPin,
        showSpace: showSpace,
      ),
      error: (err, st) => Text('Error loading pin ${err.toString()}'),
      loading: () => const Skeletonizer(child: SizedBox()),
    );
  }
}

class PinListItem extends StatefulWidget {
  final ActerPin pin;
  final bool showSpace;
  const PinListItem({
    super.key,
    required this.pin,
    this.showSpace = false,
  });

  @override
  State<PinListItem> createState() => _PinListItemState();
}

class _PinListItemState extends State<PinListItem> {
  String pinContent = '';

  @override
  void initState() {
    super.initState();
    _buildPinContent();
  }

  void _buildPinContent() async {
    MsgContent? msgContent = widget.pin.content();
    if (msgContent != null) {
      final formattedBody = msgContent.formattedBody();
      if (formattedBody != null) {
        pinContent = formattedBody;
      } else {
        pinContent = msgContent.body();
      }
    }
  }

  Future<void> openItem(BuildContext context) async {
    final String pinId = widget.pin.eventIdStr();
    await context.pushNamed(
      Routes.pin.name,
      pathParameters: {'pinId': pinId},
    );
  }

  // handler for gesture interaction on pin
  Future<void> onTap(BuildContext context) async {
    final bool isLink = widget.pin.isLink();
    if (isLink) {
      final target = widget.pin.url()!;
      await openLink(target, context);
    } else {
      await openItem(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLink = widget.pin.isLink();
    final spaceId = widget.pin.roomIdStr();

    return Card(
      child: ListTile(
        key: Key(widget.pin.eventIdStr()),
        onTap: () => onTap(context),
        onLongPress: () => openItem(context),
        title: Row(
          children: <Widget>[
            Icon(
              isLink ? Atlas.link_chain_thin : Atlas.document_thin,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.pin.title(),
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        titleTextStyle: Theme.of(context).textTheme.titleSmall,
        subtitle: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 10),
            if (widget.showSpace) Flexible(child: SpaceChip(spaceId: spaceId)),
            const SizedBox(height: 10),
            if (pinContent.isNotEmpty)
              Flexible(
                child: Html(
                  padding: const EdgeInsets.all(0),
                  data: pinContent,
                  maxLines: 2,
                  defaultTextStyle: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(overflow: TextOverflow.ellipsis),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
