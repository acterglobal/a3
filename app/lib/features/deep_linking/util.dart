import 'package:acter/features/deep_linking/types.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// would be great if that was coming right from the API
ObjectType? typeFromRefDetails(RefDetails refDetails) => switch (refDetails
    .typeStr()) {
  'pin' => ObjectType.pin,
  'task' => ObjectType.task,
  'news' => ObjectType.boost,
  'calendar-event' => ObjectType.calendarEvent,
  'task-list' => ObjectType.taskList,
  'comment' => ObjectType.comment,
  'attachment' => ObjectType.attachment,
  'space' => ObjectType.space,
  'chat' => ObjectType.chat,
  _ => null,
};

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
