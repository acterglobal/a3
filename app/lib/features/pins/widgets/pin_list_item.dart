import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

class PinListItem extends ConsumerStatefulWidget {
  final ActerPin pin;
  const PinListItem({super.key, required this.pin});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PinListItemState();
}

class _PinListItemState extends ConsumerState<PinListItem> {
  @override
  Widget build(BuildContext context) {
    final pin = widget.pin;
    final isLink = pin.isLink();
    return ListTile(
      // key: Key(pin.eventId().toString()), // FIXME: causes crashes in ffigen
      leading: Icon(isLink ? Atlas.link_chain_thin : Atlas.document_thin),
      title: Text(pin.title()),
    );
  }
}
