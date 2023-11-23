import 'package:acter/features/settings/super_invites/providers/super_invites_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
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
            decoration: const InputDecoration(
              icon: Icon(Atlas.plus_ticket_thin),
              hintText: 'An invite token you want to redeem',
              labelText: 'Token',
            ),
            controller: _tokenController,
          ),
          trailing: OutlinedButton(
            key: RedeemToken.redeemTokenSubmit,
            onPressed: _submit,
            child: const Text('redeem'),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final token = _tokenController.text;
    if (token.isEmpty) {
      return;
    }
    final superInvites = ref.read(superInvitesProvider);
    try {
      EasyLoading.show(status: 'redeeming $token');
      final rooms = (await superInvites.redeem(token)).toList();
      EasyLoading.showSuccess('Added to ${rooms.length} rooms');
      _tokenController.clear();
      FocusManager.instance.primaryFocus?.unfocus();
    } catch (err) {
      EasyLoading.showError(
        'Redeeming token failed $err',
        duration: const Duration(seconds: 3),
      );
    }
  }
}
