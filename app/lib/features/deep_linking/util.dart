import 'package:acter/features/deep_linking/types.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

// would be great if that was coming right from the API
ObjectType? typeFromRefDetails(RefDetails refDetails) =>
    switch (refDetails.typeStr()) {
      'pin' => ObjectType.pin,
      'task' => ObjectType.task,
      'news' => ObjectType.boost,
      'calendar-event' => ObjectType.calendarEvent,
      'task-list' => ObjectType.taskList,
      'comment' => ObjectType.comment,
      'attachment' => ObjectType.attachment,
      _ => null,
    };
