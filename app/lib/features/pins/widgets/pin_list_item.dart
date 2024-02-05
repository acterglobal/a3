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

class PinListItem extends ConsumerStatefulWidget {
  final String pinId;
  final bool showSpace;
  const PinListItem({
    super.key,
    required this.pinId,
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
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _buildPinContent();
    });
  }

  void _buildPinContent() async {
    ActerPin pin = await ref.read(pinProvider(widget.pinId).future);
    MsgContent? msgContent = pin.contentText();
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
    final pin = ref.watch(pinProvider(widget.pinId));

    Future<void> openItem() async {
      await context.pushNamed(
        Routes.pin.name,
        pathParameters: {'pinId': widget.pinId},
      );
    }

    Future<void> onTap(ActerPin pin) async {
      if (pin.isLink()) {
        final target = pin.url()!;
        await openLink(target, context);
      } else {
        await openItem();
      }
    }

    return pin.when(
      data: (acterPin) {
        return InkWell(
          onTap: () => onTap(acterPin),
          onLongPress: openItem,
          child: Card(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    key: Key(widget.pinId), // FIXME: causes crashes in ffigen
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Flexible(
                              child: Icon(
                                acterPin.isLink()
                                    ? Atlas.link_chain_thin
                                    : Atlas.document_thin,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                acterPin.title(),
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .copyWith(
                                      color: acterPin.isLink()
                                          ? Colors.blue
                                          : null,
                                      decorationColor: acterPin.isLink()
                                          ? Colors.blue
                                          : null,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Visibility(
                        visible: widget.showSpace,
                        child: SpaceChip(spaceId: acterPin.roomIdStr()),
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
                              icon: acterPin.isLink()
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
      },
      loading: () => const Text('Loading Pin'),
      error: (err, st) => Text('Error loading pin: ${err.toString()}'),
    );
  }
}
