import 'package:acter/common/toolkit/widgets/acter_inline_chip.dart';
import 'package:acter/features/deep_linking/actions/show_item_preview.dart';
import 'package:acter/features/deep_linking/types.dart';
import 'package:acter/features/deep_linking/util.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InlineItemPreview extends ConsumerWidget {
  final UriParseResult uriResult;
  final String? roomId;
  final void Function()? onTap;

  const InlineItemPreview({
    super.key,
    required this.uriResult,
    this.roomId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = uriResult.roomId ?? this.roomId;

    final refType = uriResult.finalType();
    final refTitle = uriResult.preview.title ?? L10n.of(context).unknown;

    final fontSize = Theme.of(context).textTheme.bodySmall?.fontSize ?? 12.0;
    return ActerInlineChip(
      tooltip: subtitleForType(context, refType),
      onTap:
          roomId == null
              ? null
              : () => showItemPreview(
                context: context,
                ref: ref,
                uriResult: uriResult,
                roomId: roomId,
              ),
      leading: Icon(getIconByType(refType), size: fontSize),
      text: refTitle,
      trailing: SizedBox(width: 4),
    );
  }
}
