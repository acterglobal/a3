import 'package:acter/features/news/controllers/news_comment_controller.dart';
import 'package:acter/features/news/widgets/reply_view.dart';
import 'package:acter/models/CommentModel.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';

class CommentView extends StatefulWidget {
  final CommentModel commentModel;
  final int postition;

  const CommentView({
    Key? key,
    required this.commentModel,
    required this.postition,
  }) : super(key: key);

  @override
  CommentViewState createState() => CommentViewState();
}

class CommentViewState extends State<CommentView> {
  bool replyView = false;
  final newsCommentController = Get.put(NewsCommentController());

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        newsCommentController.handleCommentLikeClick(widget.postition);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Slidable(
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (BuildContext context) {},
                  foregroundColor: Colors.white,
                  icon: Icons.reply,
                ),
                SlidableAction(
                  onPressed: (BuildContext context) {},
                  foregroundColor: Colors.white,
                  icon: Icons.report,
                ),
              ],
            ),
            child: Flex(
              direction: Axis.horizontal,
              children: [
                const CircleAvatar(backgroundColor: Colors.white),
                Expanded(
                  // fit: FlexFit.loose,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.commentModel.name,
                          style: TextStyle(
                            color: widget.commentModel.titleColor,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          widget.commentModel.comment,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              Text(
                                widget.commentModel.time,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text(
                                  'Reply',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        newsCommentController
                            .handleCommentLikeClick(widget.postition);
                      },
                      child: widget.commentModel.liked
                          ? const Icon(Atlas.heart, color: Colors.red)
                          : const Icon(Atlas.heart),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        widget.commentModel.likeCount.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => replyView = !replyView);
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(52, 12, 0, 8),
              child: Text(
                replyView ? 'Hide replies' : 'View replies',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          Visibility(
            visible: replyView,
            child: ListView.builder(
              itemCount: widget.commentModel.replies.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: ReplyView(
                    replyModel: widget.commentModel.replies[index],
                    commentPos: widget.postition,
                    currentPos: index,
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
