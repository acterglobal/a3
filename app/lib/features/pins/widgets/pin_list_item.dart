import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool expanded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final pin = widget.pin;
    final isLink = pin.isLink();
    final spaceId = pin.roomIdStr();

    void onTap() async {
      if (isLink) {
        final target = pin.url()!;
        final Uri? url = Uri.tryParse(target);
        if (url == null) {
          debugPrint('Opening internally: $url');
          // not a valid URL, try local routing
          context.go(target);
        } else {
          debugPrint('Opening external URL: $url');
          !await launchUrl(url);
        }
      } else {
        setState(() {
          expanded = !expanded;
        });
      }
    }

    List<Widget> content = [];
    if (expanded) {
      content.add(
        Padding(
          padding: const EdgeInsetsDirectional.all(8),
          child: Text(pin.contentText() ?? ''),
        ),
      );
    }

    return Card(
      child: InkWell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ListTile(
              key: Key(pin.eventIdStr()), // FIXME: causes crashes in ffigen
              leading:
                  Icon(isLink ? Atlas.link_chain_thin : Atlas.document_thin),
              title: Text(pin.title()),
              subtitle: widget.showSpace ? SpaceChip(spaceId: spaceId) : null,
              onTap: onTap,
              trailing: isLink
                  ? null
                  : (expanded
                      ? const Icon(Icons.chevron_left_sharp)
                      : const Icon(Icons.chevron_right_sharp)),
            ),
            ...content,
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
