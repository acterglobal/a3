import 'package:acter/features/deep_linking/types.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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

  IconData getIconByType(ObjectType? refType) => switch (refType) {
    null => PhosphorIconsThin.tagChevron,
    ObjectType.pin => Atlas.pin,
    ObjectType.calendarEvent => Atlas.calendar,
    ObjectType.taskList => Atlas.list,
    ObjectType.boost => Atlas.rocket_launch,
    ObjectType.task => Atlas.check_circle_thin,
    ObjectType.comment => Atlas.chat_dots_thin,
    ObjectType.attachment => Atlas.paperclip_thin,
    ObjectType.space => Atlas.team_group,
    ObjectType.chat => Atlas.chats,
  };

  String subtitleForType(BuildContext context, ObjectType? refType) =>
      switch (refType) {
        null => L10n.of(context).unknown,
        ObjectType.pin => L10n.of(context).pin,
        ObjectType.calendarEvent => L10n.of(context).event,
        ObjectType.taskList => L10n.of(context).taskList,
        ObjectType.task => L10n.of(context).task,
        ObjectType.boost => L10n.of(context).boost,
        ObjectType.comment => L10n.of(context).comment,
        ObjectType.attachment => L10n.of(context).attachments,
        ObjectType.space => L10n.of(context).space,
        ObjectType.chat => L10n.of(context).chat,
      };
}
