import 'dart:core';

import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionCard extends ConsumerWidget {
  final DeviceRecord deviceRecord;

  const SessionCard({
    Key? key,
    required this.deviceRecord,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isVerified = deviceRecord.verified();
    final fields = [isVerified ? 'Verified' : 'Unverified'];
    final lastSeenTs = deviceRecord.lastSeenTs();
    if (lastSeenTs != null) {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(
        lastSeenTs,
        isUtc: true,
      );
      fields.add(dateTime.toString());
    }
    final lastSeenIp = deviceRecord.lastSeenIp();
    if (lastSeenIp != null) {
      fields.add(lastSeenIp);
    }
    fields.add(deviceRecord.deviceId().toString());
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 1),
      child: ListTile(
        leading: isVerified
            ? Icon(
                Icons.verified_rounded,
                color: Theme.of(context).colorScheme.success,
              )
            : Icon(
                Icons.question_mark_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
        title: Text(deviceRecord.displayName() ?? ''),
        subtitle: Text(fields.join(' - ')),
        trailing: PopupMenuButton(
          itemBuilder: (BuildContext ctx) => <PopupMenuEntry>[
            PopupMenuItem(
              onTap: () async => await onLogout(ctx, ref),
              child: Row(
                children: [
                  const Icon(Atlas.exit_thin),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(
                      AppLocalizations.of(ctx)!.logOut,
                      style: Theme.of(ctx).textTheme.labelSmall,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () async => await onVerify(ctx, ref),
              child: Row(
                children: [
                  const Icon(Atlas.shield_exclamation_thin),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(
                      AppLocalizations.of(ctx)!.verifySession,
                      style: Theme.of(ctx).textTheme.labelSmall,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onLogout(BuildContext context, WidgetRef ref) async {
    TextEditingController usernameController = TextEditingController();
    TextEditingController passwordController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Auth data needed'),
          content: Wrap(
            children: [
              const Text('Please input username.'),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(hintText: 'Username'),
              ),
              const Text('Please input password.'),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(hintText: 'Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                if (ctx.mounted) {
                  Navigator.of(context).pop(false);
                }
              },
            ),
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                if (usernameController.text.isEmpty) {
                  return;
                }
                if (passwordController.text.isEmpty) {
                  return;
                }
                if (ctx.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
            ),
          ],
        );
      },
    );
    if (result != true) {
      return;
    }
    final client = ref.read(clientProvider);
    if (client == null) {
      throw 'Client is not logged in';
    }
    final manager = client.sessionManager();
    await manager.deleteDevices(
      [deviceRecord.deviceId().toString()] as FfiListFfiString,
      usernameController.text,
      passwordController.text,
    );
  }

  Future<void> onVerify(BuildContext context, WidgetRef ref) async {
    final client = ref.read(clientProvider);
    if (client == null) {
      throw 'Client is not logged in';
    }
    final manager = client.sessionManager();
    await manager.requestVerification(deviceRecord.deviceId().toString());
  }
}
