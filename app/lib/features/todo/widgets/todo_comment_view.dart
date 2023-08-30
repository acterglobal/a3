import 'package:acter/models/CommentModel.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {},
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
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: widget.commentModel.liked
                          ? const Icon(Icons.favorite, color: Colors.red)
                          : const Icon(Atlas.heart, color: Colors.red),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        widget.commentModel.likeCount.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
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
