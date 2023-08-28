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
                  const Text(
                    'Invite Friends',
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'You can invite your friends to ToDo today via',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      const _Divider(),
                      const Text(
                        'Whatsapp',
                      ),
                      const _Divider(),
                      const Text(
                        'Email',
                      ),
                      const _Divider(),
                      const Text(
                        'SMS',
                      ),
                      const _Divider(),
                      const Text(
                        'Invitation Link',
                      ),
                      const _Divider(),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Cancel',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
