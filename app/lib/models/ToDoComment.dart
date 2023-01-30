class ToDoComment {
  final String userId;
  final String? text;
  final DateTime time;

  const ToDoComment({
    required this.userId,
    required this.time,
    this.text,
  });
}
