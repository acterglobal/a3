// ignore_for_file: prefer_const_constructors, require_trailing_commas

import 'package:flutter/material.dart';

class MembersList extends StatefulWidget {
  const MembersList({
    Key? key,
    required this.name,
    required this.isAdmin,
  }) : super(key: key);

  final String name;
  final bool isAdmin;

  @override
  MembersListState createState() => MembersListState();
}

class MembersListState extends State<MembersList> {
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, color: Colors.white);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flex(
          direction: Axis.horizontal,
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
            ),
            Expanded(
              // fit: FlexFit.loose,
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                Visibility(
                  visible: widget.isAdmin,
                  child: Text(
                    'Admin',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            )
          ],
        ),
      ],
    );
  }
}
