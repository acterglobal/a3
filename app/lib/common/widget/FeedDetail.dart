import 'package:flutter/material.dart';

class FeedDetail extends StatelessWidget {
  const FeedDetail({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Column(
        children: const <Widget>[
          Text(
            'Lorem Ipsum is simply dummy text of the printing and',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          // ignore: prefer_const_constructors
          SizedBox(height: 10),
          // ignore: prefer_const_constructors
          Text(
            'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard since the 1500s when an unknown printer took a galley of type and scrambled',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
