typedef Bookmarker = ({BookmarkType type, String id});

// referencing the inner type
enum BookmarkType {
  events,
  pins,
  // ignore: constant_identifier_names
  task_lists,
  tasks,
  news;

  static Bookmarker forEvent(String id) => (type: BookmarkType.events, id: id);
  static Bookmarker forNewsEntry(String id) => (
    type: BookmarkType.news,
    id: id,
  );
  static Bookmarker forTaskList(String id) => (
    type: BookmarkType.task_lists,
    id: id,
  );
  static Bookmarker forTask(String id) => (type: BookmarkType.tasks, id: id);
  static Bookmarker forPins(String id) => (type: BookmarkType.pins, id: id);
}
