import 'package:acter/common/providers/network_provider.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/no_internet.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

final tokenField = GlobalKey<FormFieldState>();

class RedeemInvitationsPage extends ConsumerStatefulWidget {
  final String username;
  const RedeemInvitationsPage({super.key, required this.username});

  @override
  ConsumerState<RedeemInvitationsPage> createState() =>
      _RedeemInvitationsPageState();
}

class _RedeemInvitationsPageState extends ConsumerState<RedeemInvitationsPage> {
  final TextEditingController _tokenController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('invitation_token');
    if (token != null && token.isNotEmpty) {
      setState(() {
        _tokenController.text = token;
      });
    }
  }

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
              child: _actionButtons(context, lang),
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

  Widget _actionButtons(BuildContext context, L10n lang) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.goNamed(
              Routes.saveUsername.name,
              queryParameters: {'username': widget.username},
            ),
            child: Text(lang.skip),
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: ActerPrimaryActionButton(
            onPressed: () {
              if (!tokenField.currentState!.validate()) return;
              if (!inCI && !ref.read(hasNetworkProvider)) {
                showNoInternetNotification(context);
                return;
              }
              redeemToken(context, ref, _tokenController.text.trim());
            },
            child: Text(lang.redeem),
          ),
        ),
      ],
    );
  }

  void redeemToken(BuildContext context, WidgetRef ref, String token) async {
    final lang = L10n.of(context);
    final superInvites = await ref.read(superInvitesProvider.future);

    EasyLoading.show(status: lang.redeeming(token));
    try {
      final rooms = (await superInvites.redeem(token)).toList();
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(lang.addedToSpacesAndChats(rooms.length));
    } catch (e) {
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.redeemingFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
