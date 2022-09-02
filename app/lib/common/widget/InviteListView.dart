// ignore_for_file: prefer_const_constructors, require_trailing_commas

import 'package:effektio/common/store/themes/separatedThemes.dart';
import 'package:flutter/material.dart';

class InviteListView extends StatelessWidget {
  const InviteListView({
    Key? key,
    required this.name,
    required this.isAdded,
  }) : super(key: key);

  final String name;
  final bool isAdded;

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
                      name,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                Visibility(
                  visible: !isAdded,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppCommonTheme.greenButtonColor,
                    ),
                    child: Text(
                      'Invite',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                Visibility(
                  visible: isAdded,
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppCommonTheme.darkShade,
                      elevation: 0.0,
                    ),
                    child: Text(
                      'Invited',
                      style: TextStyle(color: Colors.white),
                    ),
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
