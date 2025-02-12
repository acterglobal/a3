import 'package:acter/features/super_invites/widgets/invite_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SuperInviteListPage extends ConsumerWidget {
  const SuperInviteListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(lang.superInvites)),
      body: InviteListWidget(),
    );
  }
}
