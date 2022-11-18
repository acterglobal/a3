import 'package:effektio/controllers/news_comment_controller.dart';
import 'package:effektio/models/CommentModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class ReplyView extends StatefulWidget {
  final ReplyModel replyModel;
  final int commentPos;
  final int currentPos;

  const ReplyView({
    Key? key,
    required this.replyModel,
    required this.currentPos,
    required this.commentPos,
  }) : super(key: key);

  @override
  ReplyViewState createState() => ReplyViewState();
}

class ReplyViewState extends State<ReplyView> {
  final newsCommentController = Get.put(NewsCommentController());

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 32, top: 12),
      child: Flex(
        direction: Axis.horizontal,
        children: [
          const CircleAvatar(backgroundColor: Colors.white),
          Flexible(
            fit: FlexFit.loose,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.replyModel.name,
                    style: TextStyle(
                        color: widget.replyModel.titleColor, fontSize: 16),
                  ),
                  Text(
                    widget.replyModel.reply,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Row(
                    children: [
                      const Text(
                        '2h',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          widget.replyModel.likeCount.toString() + ' likes',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              newsCommentController.handleReplyLikeClick(
                  widget.commentPos, widget.currentPos);
            },
            child: widget.replyModel.liked
                ? const Icon(Icons.favorite, color: Colors.red)
                : SvgPicture.asset(
                    'assets/images/heart.svg',
                    color: Colors.white,
                    width: 24,
                    height: 24,
                  ),
          ),
        ],
      ),
    );
  }
}
