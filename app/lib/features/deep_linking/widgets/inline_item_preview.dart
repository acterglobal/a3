import 'package:acter/features/deep_linking/actions/show_item_preview.dart';
import 'package:acter/features/deep_linking/types.dart';
import 'package:acter/features/deep_linking/util.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InlineItemPreview extends ConsumerWidget {
  final UriParseResult uriResult;
  final String roomId;
  final void Function()? onTap;

  const InlineItemPreview({
    super.key,
    required this.uriResult,
    required this.roomId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refType = uriResult.finalType();
    final refTitle = uriResult.preview.title ?? L10n.of(context).unknown;

    final fontSize = Theme.of(context).textTheme.bodySmall?.fontSize ?? 12.0;
    return Tooltip(
      message: subtitleForType(context, refType),
      child: InkWell(
        onTap:
            () => showItemPreview(
              context: context,
              ref: ref,
              uriResult: uriResult,
              roomId: uriResult.roomId ?? roomId,
            ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(getIconByType(refType), size: fontSize),
            SizedBox(width: 4),
            Text(refTitle),
            SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
