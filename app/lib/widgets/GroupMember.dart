import 'package:flutter/material.dart';

class GroupMember extends StatelessWidget {
  final String name;
  final bool isAdmin;

  const GroupMember({
    Key? key,
    required this.name,
    required this.isAdmin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: Axis.horizontal,
      children: [
        const CircleAvatar(
          backgroundColor: Colors.white,
        ),
        Expanded(
          // fit: FlexFit.loose,
          child: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        Visibility(
          visible: isAdmin,
          child: const Text(
            'Admin',
            style: TextStyle(color: Colors.white),
          ),
        )
      ],
    );
  }
}
