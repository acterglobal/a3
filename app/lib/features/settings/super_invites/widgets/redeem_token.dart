import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/settings/super_invites/providers/super_invites_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late SuperInvitesTokenUpdateBuilder tokenUpdater;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Form(
        key: _formKey,
        child: ListTile(
          title: TextFormField(
            key: RedeemToken.redeemTokenField,
            decoration: InputDecoration(
              icon: const Icon(Atlas.plus_ticket_thin),
              hintText: L10n.of(context).anInviteCodeYouWantToRedeem,
              labelText: L10n.of(context).inviteCode,
            ),
            controller: _tokenController,
          ),
          trailing: ActerPrimaryActionButton(
            key: RedeemToken.redeemTokenSubmit,
            onPressed: _submit,
            child: Text(L10n.of(context).redeem),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final token = _tokenController.text;
    if (token.isEmpty) return;
    final superInvites = ref.read(superInvitesProvider);

    EasyLoading.show(status: L10n.of(context).redeeming(token));
    try {
      final rooms = (await superInvites.redeem(token)).toList();
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(
        L10n.of(context).addedToSpacesAndChats(rooms.length),
      );
      _tokenController.clear();
      FocusManager.instance.primaryFocus?.unfocus();
    } catch (err) {
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).redeemingFailed(err),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
