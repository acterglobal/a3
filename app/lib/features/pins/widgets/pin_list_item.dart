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

/// Wrapper for Pin List Item
class PinListItemById extends ConsumerWidget {
  final String pinId;
  final bool showSpace;
  const PinListItemById({
    super.key,
    required this.pinId,
    this.showSpace = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(pinProvider(pinId)).when(
          data: (acterPin) => PinListItem(pin: acterPin, showSpace: showSpace),
          loading: () =>
              const Skeletonizer(child: Card(child: Column(children: []))),
          error: (err, st) => Text('Error loading pin: ${err.toString()}'),
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
  String pinContent = '';
  @override
  void initState() {
    super.initState();
    _buildPinContent();
  }

  void _buildPinContent() async {
    MsgContent? msgContent = widget.pin.contentText();
    if (msgContent != null) {
      final formattedBody = msgContent.formattedBody();
      if (formattedBody != null) {
        pinContent = formattedBody;
      } else {
        pinContent = msgContent.body();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLink = widget.pin.isLink();
    final ActerPin pin = widget.pin;
    final String pinId = pin.eventIdStr();
    final String spaceId = pin.roomIdStr();

    Future<void> openItem() async {
      await context.pushNamed(
        Routes.pin.name,
        pathParameters: {'pinId': widget.pin.eventIdStr()},
      );
    }

    Future<void> onTap(ActerPin pin) async {
      if (isLink) {
        final target = pin.url()!;
        await openLink(target, context);
      } else {
        await openItem();
      }
    }

    return InkWell(
      onTap: () => onTap(pin),
      onLongPress: openItem,
      child: Card(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                key: Key(pinId), // FIXME: causes crashes in ffigen
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Flexible(
                          child: Icon(
                            isLink
                                ? Atlas.link_chain_thin
                                : Atlas.document_thin,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            pin.title(),
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall!
                                .copyWith(
                                  color: isLink ? Colors.blue : null,
                                  decorationColor: isLink ? Colors.blue : null,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: widget.showSpace,
                    child: SpaceChip(spaceId: spaceId),
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: Row(
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth * 0.7,
                          ),
                          child: Visibility(
                            visible: pinContent.isNotEmpty,
                            child: Html(
                              data: pinContent,
                              maxLines: 1,
                              defaultTextStyle: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: widget.pin.isLink()
                              ? const Icon(
                                  Icons.open_in_full_sharp,
                                  size: 18,
                                )
                              : const Icon(
                                  Icons.chevron_right_sharp,
                                  size: 18,
                                ),
                          onPressed: openItem,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
