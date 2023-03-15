import 'package:acter/common/themes/seperated_themes.dart';
import 'package:flutter/material.dart';

class InviteListView extends StatelessWidget {
  final String name;
  final bool isAdded;

  const InviteListView({
    Key? key,
    required this.name,
    required this.isAdded,
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
        Column(
          children: [
            Visibility(
              visible: !isAdded,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppCommonTheme.greenButtonColor,
                ),
                child: const Text(
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
                child: const Text(
                  'Invited',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          ],
        )
      ],
    );
  }
}
