import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

class ShareInviteCode extends ConsumerStatefulWidget {
  final String inviteCode;

  const ShareInviteCode({super.key, required this.inviteCode});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ShareInviteCodeState();
}

class _ShareInviteCodeState extends ConsumerState<ShareInviteCode> {
  String userName = '';

  @override
  void initState() {
    super.initState();
    getUserName();
  }

  Future<void> getUserName() async {
    final account = await ref.read(accountProfileProvider.future);
    userName = account.profile.displayName ?? '';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(L10n.of(context).shareInviteCode),
      centerTitle: true,
    );
  }

  Widget _buildBody(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMessageContent(context),
            const SizedBox(height: 30),
            _buildShareIntents(context),
            const SizedBox(height: 10),
            _buildDoneButton(context),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(L10n.of(context).message),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.neutral6,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              padding: const EdgeInsets.all(10),
              child: SingleChildScrollView(
                child: Text(
                  L10n.of(context)
                      .shareInviteContent(widget.inviteCode, userName),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareIntents(BuildContext context) {
    return Wrap(
      direction: Axis.horizontal,
      alignment: WrapAlignment.center,
      spacing: 10,
      children: [
        _shareIntentsItem(
          context: context,
          iconData: Atlas.envelope,
          onTap: () => mailTo(
            toAddress: '',
            subject: 'body=${L10n.of(context).shareInviteContent(
              widget.inviteCode,
              userName,
            )}',
          ),
        ),
        _shareIntentsItem(
          context: context,
          iconData: Atlas.whatsapp,
          onTap: () => whatsappTo(
            context,
            text: L10n.of(context).shareInviteContent(
              widget.inviteCode,
              userName,
            ),
          ),
        ),
        _shareIntentsItem(
          context: context,
          iconData: Icons.ios_share_sharp,
          onTap: () {
            Share.share(
              L10n.of(context).shareInviteContent(
                widget.inviteCode,
                userName,
              ),
            );
          },
        ),
        _shareIntentsItem(
          context: context,
          iconData: Atlas.clipboard,
          onTap: () {
            Clipboard.setData(
              ClipboardData(
                text: L10n.of(context).shareInviteContent(
                  widget.inviteCode,
                  userName,
                ),
              ),
            );
            EasyLoading.showToast(L10n.of(context).messageCopiedToClipboard);
          },
        ),
      ],
    );
  }

  Widget _shareIntentsItem({
    required BuildContext context,
    required IconData iconData,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.neutral6,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(iconData),
      ),
    );
  }

  Widget _buildDoneButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: ActerPrimaryActionButton(
        onPressed: () => context.pop(),
        child: Text(L10n.of(context).done),
      ),
    );
  }
}
