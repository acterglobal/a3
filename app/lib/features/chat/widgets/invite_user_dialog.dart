import 'package:effektio/common/themes/seperated_themes.dart';
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
              horizontal: 16,
              vertical: 24,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Invite Friends',
                    style: ToDoTheme.titleTextStyle.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You can invite your friends to ToDo today via',
                    textAlign: TextAlign.center,
                    style: ToDoTheme.descriptionTextStyle.copyWith(
                      color: ToDoTheme.calendarColor,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      const _Divider(),
                      Text(
                        'Whatsapp',
                        style: ToDoTheme.titleTextStyle.copyWith(fontSize: 16),
                      ),
                      const _Divider(),
                      Text(
                        'Email',
                        style: ToDoTheme.titleTextStyle.copyWith(fontSize: 16),
                      ),
                      const _Divider(),
                      Text(
                        'SMS',
                        style: ToDoTheme.titleTextStyle.copyWith(fontSize: 16),
                      ),
                      const _Divider(),
                      Text(
                        'Invitation Link',
                        style: ToDoTheme.titleTextStyle.copyWith(fontSize: 16),
                      ),
                      const _Divider(),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Cancel',
                          style: ToDoTheme.titleTextStyle
                              .copyWith(fontSize: 16, color: Colors.red),
                        ),
                      )
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
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        height: 2,
        indent: 0,
        endIndent: 0,
        color: Colors.grey,
      ),
    );
  }
}
