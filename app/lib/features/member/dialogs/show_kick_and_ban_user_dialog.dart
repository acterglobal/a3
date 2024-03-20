import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

Future<void> showKickAndBanUserDialog(
  BuildContext context,
  Member member,
) async {
  final userId = member.userId().toString();
  final roomId = member.roomIdStr();
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      final reason = TextEditingController();
      return AlertDialog(
        title: Text('Kick & ban $userId'),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'You are about to kick and ban $userId from $roomId ',
              ),
              const Text("They won't be able to join again"),
              TextFormField(
                controller: reason,
                decoration: const InputDecoration(
                  hintText: 'optional reason',
                  labelText: 'Reason',
                ),
              ),
              const Text('Continue?'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              EasyLoading.show(status: 'Kicking & banning user');
              try {
                final maybeReason = reason.text.isNotEmpty ? reason.text : null;
                await member.kick(maybeReason);
                await member.ban(maybeReason);
                EasyLoading.showToast('User kicked & banned');
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pop();
                }
              } catch (err) {
                EasyLoading.showError(
                  'Kicking & banning user failed: \n $err"',
                );
              }
            },
            child: const Text('Yes'),
          ),
        ],
      );
    },
  );
}
