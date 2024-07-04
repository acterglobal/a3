import 'package:flutter/material.dart';

class SpaceActionsSection extends StatelessWidget {
  final String spaceId;

  const SpaceActionsSection({
    super.key,
    required this.spaceId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 500,
        color: Colors.black45,
        child: const Placeholder());
  }
}
