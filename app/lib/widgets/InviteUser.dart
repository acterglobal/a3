import 'package:beamer/beamer.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:flutter/material.dart';

class InviteUserDialog extends StatefulWidget {
  const InviteUserDialog({Key? key}) : super(key: key);

  @override
  State<InviteUserDialog> createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends State<InviteUserDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ToDoTheme.backgroundGradientColor,
      child: Wrap(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Invite Friends',
                    style: ToDoTheme.titleTextStyle.copyWith(fontSize: 18),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    'You can invite your friends to ToDo today via',
                    textAlign: TextAlign.center,
                    style: ToDoTheme.subtitleTextStyle.copyWith(
                      color: ToDoTheme.calendarColor,
                      fontSize: 15,),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Column(
                    children: [
                      buildDivider(),
                      Text('Whatsapp', style : ToDoTheme.titleTextStyle.copyWith(fontSize: 16)),
                      buildDivider(),
                      Text('Email', style : ToDoTheme.titleTextStyle.copyWith(fontSize: 16)),
                      buildDivider(),
                      Text('SMS', style : ToDoTheme.titleTextStyle.copyWith(fontSize: 16)),
                      buildDivider(),
                      Text('Invitation Link', style : ToDoTheme.titleTextStyle.copyWith(fontSize: 16)),
                      buildDivider(),
                      GestureDetector(
                        onTap: (){
                          Beamer.of(context).beamBack();
                        },
                        child: Text('Cancel', style : ToDoTheme.titleTextStyle.copyWith(fontSize: 16, color: Colors.red)),)
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child: Divider(
        height: 2,
        indent: 0,
        endIndent: 0,
        color: Colors.grey,
      ),
    );
  }
}
