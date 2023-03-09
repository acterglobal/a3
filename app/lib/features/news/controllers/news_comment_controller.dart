import 'package:acter/models/CommentModel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NewsCommentController extends GetxController {
  // Mock data for comment and reply
  List<CommentModel> listComments = <CommentModel>[
    CommentModel(
      '',
      'Cristiano Ronaldo',
      Colors.blue,
      'Interesting',
      '10m',
      true,
      12,
      [
        ReplyModel(
          '',
          'John Cena',
          Colors.brown,
          'Replies are cool',
          '5m',
          false,
          6,
        ),
        ReplyModel(
          '',
          'John Cena',
          Colors.brown,
          'Replies are cool',
          '5m',
          false,
          6,
        ),
        ReplyModel(
          '',
          'John Cena',
          Colors.brown,
          'Replies are cool',
          '5m',
          false,
          6,
        ),
      ],
    ),
    CommentModel(
      '',
      'Lionel Messi',
      Colors.orange,
      'Well, Its considerable',
      '12m',
      false,
      10,
      [
        ReplyModel(
          '',
          'John Cena',
          Colors.brown,
          'Replies are cool',
          '5m',
          false,
          6,
        ),
        ReplyModel(
          '',
          'John Cena',
          Colors.brown,
          'Replies are cool',
          '5m',
          true,
          2,
        ),
      ],
    ),
    CommentModel(
      '',
      'Neymar Jr.',
      Colors.brown,
      'Since it came to this, we will consider it',
      '18m',
      false,
      2,
      [
        ReplyModel(
          '',
          'John Cena',
          Colors.brown,
          'Replies are cool',
          '5m',
          false,
          0,
        ),
      ],
    ),
    CommentModel(
      '',
      'Kevin De Bruyne',
      Colors.blueGrey,
      'Nice to see some progress',
      '22m',
      true,
      1,
      [
        ReplyModel(
          '',
          'John Cena',
          Colors.brown,
          'Replies are cool',
          '5m',
          false,
          7,
        ),
      ],
    ),
    CommentModel(
      '',
      'Kylian Mbappe',
      Colors.deepPurple,
      'Really great',
      '24m',
      false,
      0,
      [
        ReplyModel(
          '',
          'John Cena',
          Colors.brown,
          'Replies are cool',
          '5m',
          true,
          6,
        ),
      ],
    ),
    CommentModel(
      '',
      'Virgil Van Dijk',
      Colors.indigo,
      "Can't be true",
      '29m',
      false,
      0,
      [
        ReplyModel(
          '',
          'John Cena',
          Colors.brown,
          'Replies are cool',
          '5m',
          false,
          0,
        ),
      ],
    ),
    CommentModel(
      '',
      'Mohamed Salah',
      Colors.green,
      'This comment feature is nice',
      '40m',
      false,
      0,
      [
        ReplyModel(
          '',
          'John Cena',
          Colors.brown,
          'Replies are cool',
          '5m',
          false,
          6,
        ),
      ],
    ),
    CommentModel(
      '',
      'Sadio Mane',
      Colors.yellow,
      'So comments are here.... really cool',
      '40m',
      false,
      4,
      [
        ReplyModel(
          '',
          'John Cena',
          Colors.brown,
          'Replies are cool',
          '5m',
          true,
          6,
        ),
      ],
    ),
    CommentModel(
      '',
      'Sergio Ramos',
      Colors.lime,
      'Appreciated',
      '40m',
      true,
      5,
      [
        ReplyModel(
          '',
          'John Cena',
          Colors.brown,
          'Replies are cool',
          '5m',
          true,
          6,
        ),
      ],
    ),
    CommentModel(
      '',
      'Paul Pogba',
      Colors.teal,
      'You can double tap to like it now',
      '40m',
      false,
      9,
      [
        ReplyModel(
          '',
          'John Cena',
          Colors.brown,
          'Replies are cool',
          '5m',
          true,
          6,
        ),
      ],
    ),
    CommentModel(
      '',
      'Bruno Fernandes',
      Colors.red,
      'Double tap works too... yes',
      '2h',
      false,
      0,
      [
        ReplyModel(
          '',
          'John Cena',
          Colors.brown,
          'Replies are cool',
          '5m',
          false,
          0,
        ),
      ],
    ),
  ];

  void handleCommentLikeClick(int position) {
    // Todo : change implementation later as per actual api data
    var commentModel = listComments[position];
    if (commentModel.liked) {
      commentModel.liked = false;
      commentModel.likeCount = commentModel.likeCount - 1;
    } else {
      commentModel.liked = true;
      commentModel.likeCount = commentModel.likeCount + 1;
    }
    update();
  }

  void handleReplyLikeClick(int commentPosition, int replyPostition) {
    // Todo : change implementation later as per actual api data
    var data = listComments[commentPosition].replies[replyPostition];
    if (data.liked) {
      data.liked = false;
      data.likeCount = data.likeCount - 1;
    } else {
      data.liked = true;
      data.likeCount = data.likeCount + 1;
    }
    update();
  }
}
