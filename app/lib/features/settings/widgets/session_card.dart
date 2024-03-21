import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/cross_signing/providers/verification_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:breadcrumbs/breadcrumbs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionCard extends ConsumerWidget {
  final DeviceRecord deviceRecord;

  const SessionCard({super.key, required this.deviceRecord});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isVerified = deviceRecord.isVerified();
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
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 15),
      child: ListTile(
        leading: isVerified
            ? Icon(
                Atlas.check_shield_thin,
                color: Theme.of(context).colorScheme.success,
              )
            : Icon(
                Atlas.xmark_shield_thin,
                color: Theme.of(context).colorScheme.error,
              ),
        title: Text(deviceRecord.displayName() ?? ''),
        subtitle: Breadcrumbs(
          crumbs: fields.map((e) => TextSpan(text: e)).toList(),
          separator: ' - ',
        ),
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
                      'Logout',
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
                      'Verify Session',
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
    TextEditingController passwordController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Authentication required'),
          content: Wrap(
            children: [
              const Text(
                'Please provide your user password to confirm you want to end that session.',
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
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
    final client = ref.read(alwaysClientProvider);
    final manager = client.sessionManager();
    await manager.deleteDevices(
      [deviceRecord.deviceId().toString()] as FfiListFfiString,
      client.userId().toString(),
      passwordController.text,
    );
  }

  Future<void> onVerify(BuildContext context, WidgetRef ref) async {
    final devId = deviceRecord.deviceId().toString();
    final client = ref.read(alwaysClientProvider);
    // final manager = client.sessionManager();

    final event = await client.requestVerification(devId);
    // start request event loop
    await client.installRequestEventHandler(event.flowId());

    // force request.created, because above loop starts from request.ready
    ref.read(verificationStateProvider.notifier).launchFlow(event);
  }
}
