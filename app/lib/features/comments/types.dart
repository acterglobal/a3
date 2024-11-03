import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show ActerPin, CalendarEvent, CommentsManager, NewsEntry, Task, TaskList;

abstract interface class CommentsManagerProvider {
  Future<CommentsManager> getManager();
}

class TaskListCommentsManagerProvider implements CommentsManagerProvider {
  final TaskList inner;
  late String innerId;

  TaskListCommentsManagerProvider(this.inner) {
    innerId = inner.eventIdStr();
  }

  @override
  Future<CommentsManager> getManager() => inner.comments();

  @override
  int get hashCode => innerId.hashCode;
  @override
  bool operator ==(other) =>
      other is TaskListCommentsManagerProvider && innerId == other.innerId;
}

extension TaskListCommentsManagerProviderExtension on TaskList {
  TaskListCommentsManagerProvider asCommentsManagerProvider() =>
      TaskListCommentsManagerProvider(this);
}

class TaskCommentsManagerProvider implements CommentsManagerProvider {
  final Task inner;
  late String innerId;

  TaskCommentsManagerProvider(this.inner) {
    innerId = inner.eventIdStr();
  }

  @override
  Future<CommentsManager> getManager() => inner.comments();

  @override
  int get hashCode => innerId.hashCode;

  @override
  bool operator ==(other) =>
      other is TaskCommentsManagerProvider && innerId == other.innerId;
}

extension TaskCommentsManagerProviderExtension on Task {
  TaskCommentsManagerProvider asCommentsManagerProvider() =>
      TaskCommentsManagerProvider(this);
}

class NewsEntryCommentsManagerProvider implements CommentsManagerProvider {
  final NewsEntry inner;
  late String innerId;

  NewsEntryCommentsManagerProvider(this.inner) {
    innerId = inner.eventId().toString();
  }

  @override
  Future<CommentsManager> getManager() => inner.comments();

  @override
  int get hashCode => innerId.hashCode;
  @override
  bool operator ==(other) =>
      other is NewsEntryCommentsManagerProvider && innerId == other.innerId;
}

extension NewsEntryCommentsManagerProviderExtension on NewsEntry {
  NewsEntryCommentsManagerProvider asCommentsManagerProvider() =>
      NewsEntryCommentsManagerProvider(this);
}

class ActerPinCommentsManagerProvider implements CommentsManagerProvider {
  final ActerPin inner;
  late String innerId;

  ActerPinCommentsManagerProvider(this.inner) {
    innerId = inner.eventIdStr();
  }

  @override
  Future<CommentsManager> getManager() => inner.comments();

  @override
  int get hashCode => innerId.hashCode;
  @override
  bool operator ==(other) =>
      other is ActerPinCommentsManagerProvider && innerId == other.innerId;
}

extension ActerPinCommentsManagerProviderExtension on ActerPin {
  ActerPinCommentsManagerProvider asCommentsManagerProvider() =>
      ActerPinCommentsManagerProvider(this);
}

class CalendarEventCommentsManagerProvider implements CommentsManagerProvider {
  final CalendarEvent inner;
  late String innerId;

  CalendarEventCommentsManagerProvider(this.inner) {
    innerId = inner.eventId().toString();
  }

  @override
  Future<CommentsManager> getManager() => inner.comments();

  @override
  int get hashCode => innerId.hashCode;
  @override
  bool operator ==(other) =>
      other is CalendarEventCommentsManagerProvider && innerId == other.innerId;
}

extension CalendarEventCommentsManagerProviderExtension on CalendarEvent {
  CalendarEventCommentsManagerProvider asCommentsManagerProvider() =>
      CalendarEventCommentsManagerProvider(this);
}
