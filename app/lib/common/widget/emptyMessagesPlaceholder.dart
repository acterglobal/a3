import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EmptyPlaceholder extends StatelessWidget {
  const EmptyPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: MediaQuery.of(context).size.height / 6),
        SvgPicture.asset('assets/images/emptyPlaceholder.svg'),
        const SizedBox(height: 10),
        const Text(
          'No Messages here yet ...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Start the conversation by sending the message',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
