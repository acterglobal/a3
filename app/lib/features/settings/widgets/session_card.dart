import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/cross_signing/providers/verification_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/settings/providers/session_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:breadcrumbs/breadcrumbs.dart';
import 'package:extension_nullable/extension_nullable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionCard extends ConsumerWidget {
  final DeviceRecord deviceRecord;

  const SessionCard({super.key, required this.deviceRecord});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isVerified = deviceRecord.isVerified();
    final fields = [
      isVerified ? L10n.of(context).verified : L10n.of(context).unverified,
    ];
    deviceRecord.lastSeenTs().map((p0) {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(p0, isUtc: true);
      fields.add(dateTime.toLocal().toString());
    });
    deviceRecord.lastSeenIp().map((p0) => fields.add(p0));
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
          itemBuilder: (BuildContext context) => <PopupMenuEntry>[
            PopupMenuItem(
              onTap: () async => await onLogout(context, ref),
              child: Row(
                children: [
                  const Icon(Atlas.exit_thin),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(
                      L10n.of(context).logOut,
                      style: Theme.of(context).textTheme.labelSmall,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () async => await onVerify(context, ref),
              child: Row(
                children: [
                  const Icon(Atlas.shield_exclamation_thin),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(
                      L10n.of(context).verifySession,
                      style: Theme.of(context).textTheme.labelSmall,
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
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(L10n.of(context).authenticationRequired),
          content: Wrap(
            children: [
              Text(L10n.of(context).pleaseProvideYourUserPassword),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: L10n.of(context).password,
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              child: Text(L10n.of(context).cancel),
              onPressed: () {
                if (context.mounted) {
                  Navigator.pop(context, false);
                }
              },
            ),
            ActerPrimaryActionButton(
              child: Text(L10n.of(context).ok),
              onPressed: () {
                if (passwordController.text.isEmpty) {
                  return;
                }
                if (context.mounted) {
                  Navigator.pop(context, true);
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
    await manager.deleteDevice(
      deviceRecord.deviceId().toString(),
      client.userId().toString(),
      passwordController.text,
    );
    ref.invalidate(allSessionsProvider); // DeviceUpdates doesn’t cover logout
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
