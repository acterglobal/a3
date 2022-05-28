// ignore_for_file: prefer_const_constructors

import 'package:effektio/common/widget/ReplyView.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CommentView extends StatefulWidget {
  const CommentView({
    Key? key,
    required this.name,
    required this.titleColor,
    required this.comment,
  }) : super(key: key);

  final String name;
  final Color titleColor;
  final String comment;
  @override
  CommentViewState createState() => CommentViewState();
}

class CommentViewState extends State<CommentView> {
  bool replyView = false;
  bool liked = false;
  int likeCount = 0;
  late FocusNode myFocusNode;

  @override
  void initState() {
    super.initState();
    myFocusNode = FocusNode();
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    super.dispose();
  }

  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, color: Colors.white);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flex(
          direction: Axis.horizontal,
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
            ),
            Flexible(
              fit: FlexFit.loose,
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(color: widget.titleColor, fontSize: 16),
                    ),
                    Text(
                      widget.comment,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Row(
                        children: [
                          Text(
                            '2h',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                replyView = replyView ? false : true;
                              });
                            },
                            child: Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text(
                                'Reply',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14),
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
                if (liked == false)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        liked = true;
                        likeCount = likeCount + 1;
                      });
                    },
                    child: SvgPicture.asset(
                      'assets/images/heart.svg',
                      color: Colors.white,
                      width: 24,
                      height: 24,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        liked = false;
                        likeCount = likeCount - 1;
                      });
                    },
                    child: Icon(
                      Icons.favorite,
                      color: Colors.red,
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    likeCount.toString(),
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            ),
          ],
        ),
        Visibility(
          visible: replyView,
          child: Column(
            children: const [
              ReplyView(
                name: 'Abhishek',
                titleColor: Colors.deepOrange,
                reply: 'comment reply',
              )
            ],
          ),
        )
      ],
    );
  }
}
