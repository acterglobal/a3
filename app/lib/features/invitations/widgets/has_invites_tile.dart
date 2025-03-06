import 'package:acter/common/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class HasInvitesTile extends ConsumerWidget {
  final int count;
  const HasInvitesTile({super.key, required this.count});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: const BorderRadius.all(Radius.circular(100)),
            ),
            child: Icon(
              PhosphorIconsRegular.envelopeSimple,
              color: Theme.of(context).colorScheme.onSecondary,
            ),
          ),
          onTap: () => context.pushNamed(Routes.myOpenInvitations.name),
          title: Text(L10n.of(context).pendingInvitesCount(count)),
          trailing: const Icon(PhosphorIconsRegular.caretRight),
        ),
      ),
    );
  }
}
