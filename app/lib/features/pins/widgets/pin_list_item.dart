import 'package:acter/features/attachments/providers/attachment_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/attachments/widgets/attachment_item.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

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
      error: (err, st) => Text(L10n.of(context).errorLoading(err)),
      loading: () => const Skeletonizer(
        child: SizedBox(
          height: 100,
          width: 100,
        ),
      ),
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
  ConsumerState<PinListItem> createState() => _PinListItemConsumerState();
}

class _PinListItemConsumerState extends ConsumerState<PinListItem> {
  String pinContent = '';

  @override
  void initState() {
    super.initState();
    _buildPinContent();
  }

  // keeps list item up-to-date with pin content changes
  @override
  void didUpdateWidget(PinListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldContent = oldWidget.pin.content();
    final newContent = widget.pin.content();
    if (oldContent != null && newContent != null) {
      if (oldContent.body() != newContent.body()) {
        _buildPinContent();
        setState(() {});
      }
    }
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
      await openItem(context);
  }

  @override
  Widget build(BuildContext context) {
    final isLink = widget.pin.isLink();
    final spaceId = widget.pin.roomIdStr();
    final asyncManager =
        ref.watch(attachmentsManagerProvider(widget.pin.attachments()));
    final attachmentsWidget = [];

    if (asyncManager.valueOrNull != null) {
      final attachments =
          ref.watch(attachmentsProvider(asyncManager.requireValue));
      if (attachments.valueOrNull != null) {
        final list = attachments.requireValue;

        if (list.isNotEmpty) {
          final attachmentId = list[0].attachmentIdStr();
          attachmentsWidget.add(
            AttachmentItem(
              key: Key(attachmentId),
              attachment: list[0],
              openView: false,
            ),
          );
        }
      }
    }

    return InkWell(
      key: Key(widget.pin.eventIdStr()),
      onTap: () => onTap(context),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
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
                    const SizedBox(height: 10),
                    if (widget.showSpace) SpaceChip(spaceId: spaceId),
                    const SizedBox(height: 10),
                    if (pinContent.isNotEmpty)
                      Html(
                        padding: const EdgeInsets.all(5),
                        data: pinContent,
                        maxLines: 2,
                        defaultTextStyle: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(overflow: TextOverflow.ellipsis),
                      ),
                  ],
                ),
              ),
              ...attachmentsWidget,
            ],
          ),
        ),
      ),
    );
  }
}
