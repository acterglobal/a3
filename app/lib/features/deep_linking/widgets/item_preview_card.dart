import 'package:acter/features/deep_linking/types.dart';
import 'package:acter/features/deep_linking/util.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';

class ItemPreviewCard extends StatelessWidget {
  final ObjectType? refType;
  final String? title;
  final EdgeInsets? margin;
  final void Function()? onTap;

  const ItemPreviewCard({
    super.key,
    required this.refType,
    this.title,
    this.onTap,
    this.margin = const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
  });

  @override
  Widget build(BuildContext context) {
    final refTitle = title ?? L10n.of(context).unknown;
    return Card(
      margin: margin,
      child: ListTile(
        leading: Icon(getIconByType(refType), size: 25),
        title: Text(refTitle),
        subtitle: Text(subtitleForType(context, refType)),
        onTap: onTap,
      ),
    );
  }
}
