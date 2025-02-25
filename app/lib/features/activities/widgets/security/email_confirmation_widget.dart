import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const Key unconfirmedEmailsKey = Key('activities-has-unconfirmed-emails');

class EmailConfirmationWidget extends ConsumerWidget {
  const EmailConfirmationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final hasUnconfirmedEmails = ref.watch(hasUnconfirmedEmailAddresses);
    if (!hasUnconfirmedEmails) return SizedBox.shrink();

    return Card(
      key: unconfirmedEmailsKey,
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 15),
      child: ListTile(
        onTap: () => context.goNamed(Routes.emailAddresses.name),
        leading: const Icon(Atlas.envelope_minus_thin),
        title: Text(lang.unconfirmedEmailsActivityTitle),
        subtitle: Text(lang.unconfirmedEmailsActivitySubtitle),
        trailing: const Icon(Icons.keyboard_arrow_right_outlined),
      ),
    );
  }
}
