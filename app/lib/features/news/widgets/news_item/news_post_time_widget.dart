import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class NewsPostTimeWidget extends StatelessWidget {
  final int originServerTs;

  const NewsPostTimeWidget({
    super.key,
    required this.originServerTs,
  });

  @override
  Widget build(BuildContext context) {
    final agoTime = Jiffy.parseFromDateTime(
      DateTime.fromMillisecondsSinceEpoch(
        originServerTs,
        isUtc: true,
      ),
    ).fromNow();
    return Row(
      children: [
        Icon(
          PhosphorIcons.timer(),
          size: 20,
        ),
        const SizedBox(width: 4),
        Text(
          agoTime,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ],
    );
  }
}
