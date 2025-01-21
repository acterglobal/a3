import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/cross_signing/providers/verification_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/settings/providers/session_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:breadcrumbs/breadcrumbs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionCard extends ConsumerWidget {
  final DeviceRecord deviceRecord;

  const SessionCard({
    super.key,
    required this.deviceRecord,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    bool isVerified = deviceRecord.isVerified();
    final crumbs = [isVerified ? lang.verified : lang.unverified];
    final lastSeenTs = deviceRecord.lastSeenTs();
    if (lastSeenTs != null) {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(
        lastSeenTs,
        isUtc: true,
      );
      crumbs.add(dateTime.toLocal().toString());
    }
    final lastSeenIp = deviceRecord.lastSeenIp();
    if (lastSeenIp != null) {
      crumbs.add(lastSeenIp);
    }
    crumbs.add(deviceRecord.deviceId().toString());
    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: 2,
        horizontal: 15,
      ),
      child: ListTile(
        leading: isVerified
            ? Icon(
                Atlas.check_shield_thin,
                color: colorScheme.success,
              )
            : Icon(
                Atlas.xmark_shield_thin,
                color: colorScheme.error,
              ),
        title: Text(deviceRecord.displayName() ?? ''),
        subtitle: Breadcrumbs(
          crumbs: [
            for (final crumb in crumbs) TextSpan(text: crumb),
          ],
          separator: ' - ',
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => <PopupMenuEntry>[
            PopupMenuItem(
              onTap: () async => await onLogout(context, ref),
              child: Row(
                children: [
                  const Icon(Atlas.exit_thin),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(
                      lang.logOut,
                      style: textTheme.labelSmall,
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
                      lang.verifySession,
                      style: textTheme.labelSmall,
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
      builder: (context) {
        final lang = L10n.of(context);
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(lang.authenticationRequired),
          content: Wrap(
            children: [
              Text(lang.pleaseProvideYourUserPassword),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(hintText: lang.password),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              child: Text(lang.cancel),
              onPressed: () {
                if (context.mounted) {
                  Navigator.pop(context, false);
                }
              },
            ),
            ActerPrimaryActionButton(
              child: Text(lang.ok),
              onPressed: () {
                if (passwordController.text.isEmpty) return;
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              },
            ),
          ],
        );
      },
    );
    if (result != true) return;
    final client = await ref.read(alwaysClientProvider.future);
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
    final client = await ref.read(alwaysClientProvider.future);
    // final manager = client.sessionManager();

    final event = await client.requestVerification(devId);
    // start request event loop
    await client.installRequestEventHandler(event.flowId());

    // force request.created, because above loop starts from request.ready
    ref.read(verificationStateProvider.notifier).launchFlow(event);
  }
}
