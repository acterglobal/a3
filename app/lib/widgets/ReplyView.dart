import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ReplyView extends StatefulWidget {
  const ReplyView({
    Key? key,
    required this.name,
    required this.titleColor,
    required this.reply,
  }) : super(key: key);

  final String name;
  final Color titleColor;
  final String reply;

  @override
  ReplyViewState createState() => ReplyViewState();
}

class ReplyViewState extends State<ReplyView> {
  bool liked = false;
  int likeCount = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 50, top: 12),
      child: Flex(
        direction: Axis.horizontal,
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
          ),
          Flexible(
            fit: FlexFit.loose,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: TextStyle(color: widget.titleColor, fontSize: 16),
                  ),
                  Text(
                    widget.reply,
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
                          likeCount.toString() + ' likes',
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
              child: const Icon(
                Icons.favorite,
                color: Colors.red,
              ),
            ),
        ],
      ),
    );
  }
}
