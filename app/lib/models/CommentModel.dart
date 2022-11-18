import 'dart:ui';

class CommentModel {
  final String avatar;
  final String name;
  final Color titleColor;
  final String comment;
  final String time;
  bool liked;
  int likeCount;
  List<ReplyModel> replies;

  CommentModel(
    this.avatar,
    this.name,
    this.titleColor,
    this.comment,
    this.time,
    this.liked,
    this.likeCount,
    this.replies,
  );
}

class ReplyModel {
  final String avatar;
  final String name;
  final Color titleColor;
  final String reply;
  final String time;
  bool liked;
  int likeCount;

  ReplyModel(
    this.avatar,
    this.name,
    this.titleColor,
    this.reply,
    this.time,
    this.liked,
    this.likeCount,
  );
}
