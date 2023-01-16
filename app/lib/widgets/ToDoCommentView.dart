import 'package:effektio/controllers/news_comment_controller.dart';
import 'package:effektio/models/CommentModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class ToDoCommentView extends StatefulWidget {
  final CommentModel commentModel;
  final int postition;

  const ToDoCommentView({
    Key? key,
    required this.commentModel,
    required this.postition,
  }) : super(key: key);

  @override
  ToDoCommentViewState createState() => ToDoCommentViewState();
}

class ToDoCommentViewState extends State<ToDoCommentView> {
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
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
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
                    padding: const EdgeInsets.only(left: 12.0),
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
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Row(
                            children: [
                              Text(
                                widget.commentModel.time,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
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
                          ? const Icon(Icons.favorite, color: Colors.red)
                          : SvgPicture.asset(
                              'assets/images/heart.svg',
                              color: Colors.white,
                              width: 24,
                              height: 24,
                            ),
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
        ],
      ),
    );
  }
}
