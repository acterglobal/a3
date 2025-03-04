import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/super_invites/dialogs/redeem_dialog.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RedeemToken extends ConsumerStatefulWidget {
  static Key redeemTokenField = const Key('super-invites-redeem-txt');
  static Key redeemTokenSubmit = const Key('super-invites-redeem-submit');

  final SuperInvitesTokenUpdateBuilder? tokenUpdater;

  const RedeemToken({super.key, this.tokenUpdater});

  @override
  ConsumerState<RedeemToken> createState() => _RedeemTokenConsumerState();
}

class _RedeemTokenConsumerState extends ConsumerState<RedeemToken> {
  final TextEditingController _tokenController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(
    debugLabel: 'redeem super invites form',
  );
  late SuperInvitesTokenUpdateBuilder tokenUpdater;

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return Card(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                lang.redeemInviteCode,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SizedBox(height: 14),
            ListTile(
              title: TextFormField(
                key: RedeemToken.redeemTokenField,
                decoration: InputDecoration(
                  icon: const Icon(Atlas.plus_ticket_thin),
                  hintText: lang.anInviteCodeYouWantToRedeem,
                  labelText: lang.inviteCode,
                ),
                controller: _tokenController,
              ),
            ),
            SizedBox(height: 14),
            ActerPrimaryActionButton(
              key: RedeemToken.redeemTokenSubmit,
              onPressed: _submit,
              child: Text(lang.redeem),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final token = _tokenController.text;
    if (token.isEmpty) return;
    final redeemed = await showReedemTokenDialog(context, ref, token);
    if (redeemed) {
      _tokenController.clear();
    }
  }
}
