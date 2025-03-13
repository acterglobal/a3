import 'dart:io';

import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show ActerPin, CalendarEvent, AttachmentsManager, Task, TaskList;

import 'package:acter/common/models/types.dart';

typedef OnAttachmentSelected =
    Future<void> Function(List<File> files, AttachmentType attachmentType);
typedef OnLinkSelected = Future<void> Function(String title, String link);

/// This is the actual input type for the providers and widget of this feature
/// the way to get this is through implementing a "wrapper" type for the getter
/// and make sure that the manager hash-id and equal is bound to the inner
/// event type to ensure we don't unnecessarily refresh the UI for unrelated
/// updates
abstract interface class AttachmentsManagerProvider {
  Future<AttachmentsManager> getManager();
}

class TaskListAttachmentsManagerProvider implements AttachmentsManagerProvider {
  final TaskList inner;
  late String innerId;

  TaskListAttachmentsManagerProvider(this.inner) {
    innerId = inner.eventIdStr();
  }

  @override
  Future<AttachmentsManager> getManager() => inner.attachments();

  @override
  int get hashCode => innerId.hashCode;
  @override
  bool operator ==(other) =>
      other is TaskListAttachmentsManagerProvider && innerId == other.innerId;
}

extension TaskListAttachmentsManagerProviderExtension on TaskList {
  TaskListAttachmentsManagerProvider asAttachmentsManagerProvider() =>
      TaskListAttachmentsManagerProvider(this);
}

class TaskAttachmentsManagerProvider implements AttachmentsManagerProvider {
  final Task inner;
  late String innerId;

  TaskAttachmentsManagerProvider(this.inner) {
    innerId = inner.eventIdStr();
  }

  @override
  Future<AttachmentsManager> getManager() => inner.attachments();

  @override
  int get hashCode => innerId.hashCode;

  @override
  bool operator ==(other) =>
      other is TaskAttachmentsManagerProvider && innerId == other.innerId;
}

extension TaskAttachmentsManagerProviderExtension on Task {
  TaskAttachmentsManagerProvider asAttachmentsManagerProvider() =>
      TaskAttachmentsManagerProvider(this);
}

class ActerPinAttachmentsManagerProvider implements AttachmentsManagerProvider {
  final ActerPin inner;
  late String innerId;

  ActerPinAttachmentsManagerProvider(this.inner) {
    innerId = inner.eventIdStr();
  }

  @override
  Future<AttachmentsManager> getManager() => inner.attachments();

  @override
  int get hashCode => innerId.hashCode;
  @override
  bool operator ==(other) =>
      other is ActerPinAttachmentsManagerProvider && innerId == other.innerId;
}

extension ActerPinAttachmentsManagerProviderExtension on ActerPin {
  ActerPinAttachmentsManagerProvider asAttachmentsManagerProvider() =>
      ActerPinAttachmentsManagerProvider(this);
}

class CalendarEventAttachmentsManagerProvider
    implements AttachmentsManagerProvider {
  final CalendarEvent inner;
  late String innerId;

  CalendarEventAttachmentsManagerProvider(this.inner) {
    innerId = inner.eventId().toString();
  }

  @override
  Future<AttachmentsManager> getManager() => inner.attachments();

  @override
  int get hashCode => innerId.hashCode;
  @override
  bool operator ==(other) =>
      other is CalendarEventAttachmentsManagerProvider &&
      innerId == other.innerId;
}

extension CalendarEventAttachmentsManagerProviderExtension on CalendarEvent {
  CalendarEventAttachmentsManagerProvider asAttachmentsManagerProvider() =>
      CalendarEventAttachmentsManagerProvider(this);
}
