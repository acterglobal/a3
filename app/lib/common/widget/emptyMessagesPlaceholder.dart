import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EmptyPlaceholder extends StatelessWidget {
  const EmptyPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: MediaQuery.of(context).size.height / 6),
        SvgPicture.asset('assets/images/emptyPlaceholder.svg'),
        const SizedBox(height: 10),
        Text('No Messages here yet ...', style: _textTheme.titleMedium),
        const SizedBox(height: 20),
        Text(
          'Start the conversation by sending the message',
          style: _textTheme.labelMedium,
        ),
      ],
    );
  }
}
