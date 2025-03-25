import 'package:acter/common/providers/network_provider.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/widgets/no_internet.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tokenField = GlobalKey<FormFieldState>();

class RedeemInvitationsPage extends ConsumerStatefulWidget {
  const RedeemInvitationsPage({super.key});

  @override
  ConsumerState<RedeemInvitationsPage> createState() =>
      _RedeemInvitationsPageState();
}

class _RedeemInvitationsPageState extends ConsumerState<RedeemInvitationsPage> {
  final TextEditingController _tokenController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, lang),
                  const SizedBox(height: 16),
                  _buildDescription(context, lang),
                  const SizedBox(height: 20),
                  _buildInviteCodeInput(context, lang),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: _actionButtons(lang),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, L10n lang) {
    return Text(
      lang.redeemInvitation,
      style: Theme.of(context).textTheme.titleLarge,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription(BuildContext context, L10n lang) {
    return Text(
      lang.redeemInvitationDescription,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 15),
    );
  }

  Widget _buildInviteCodeInput(BuildContext context, L10n lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.inviteCode),
        const SizedBox(height: 5),
        Form(
          key: _formKey,
          child: TextFormField(
            key: tokenField,
            controller: _tokenController,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
            validator:
              (val) =>
                  val == null || val.trim().isEmpty ? lang.emptyToken : null,
            decoration: InputDecoration(
              hintText: lang.inviteCode,
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code),
                onPressed: () {},
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButtons(L10n lang) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(onPressed: () {}, child: Text(lang.skip)),
        ),
        SizedBox(width: 22),
        Expanded(
          child: ActerPrimaryActionButton(
            onPressed: () {
              if (!tokenField.currentState!.validate()) return;
              if (!inCI && !ref.read(hasNetworkProvider)) {
                showNoInternetNotification(context);
                return;
              }
            },
            child: Text(lang.redeem),
          ),
        ),
      ],
    );
  }
}
