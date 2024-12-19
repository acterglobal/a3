import 'package:acter/common/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class HasInvitesTile extends ConsumerWidget {
  final int count;
  const HasInvitesTile({super.key, required this.count});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(PhosphorIconsRegular.envelopeSimple),
      onTap: () => context.pushNamed(Routes.myOpenInvitations.name),
      title: Text(L10n.of(context).pendingInvitesCount(count)),
      trailing: const Icon(PhosphorIconsRegular.caretRight),
    );
  }
}
