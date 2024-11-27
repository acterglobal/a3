import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/deep_linking/actions/show_qr_code.dart';
import 'package:acter/features/share/actions/mail_to.dart';
import 'package:acter/features/share/actions/share_to_whatsapp.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

class ShareInviteCode extends ConsumerWidget {
  final String inviteCode;
  final String roomId;

  const ShareInviteCode({
    super.key,
    required this.inviteCode,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context, ref),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(L10n.of(context).shareInviteCode),
      centerTitle: true,
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final displayName =
        ref.watch(roomDisplayNameProvider(roomId)).valueOrNull ?? '';
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMessageContent(
              context,
              ref,
              displayName,
              displayName,
            ),
            const SizedBox(height: 30),
            _buildShareIntents(
              context,
              ref,
              displayName,
              displayName,
            ),
            const SizedBox(height: 10),
            _buildDoneButton(context),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(
    BuildContext context,
    WidgetRef ref,
    String displayName,
    String roomName,
  ) {
    final lang = L10n.of(context);
    final content = lang.shareInviteContent(inviteCode, roomName, displayName);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(lang.message),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              padding: const EdgeInsets.all(10),
              child: SingleChildScrollView(
                child: Text(content),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareIntents(
    BuildContext context,
    WidgetRef ref,
    String displayName,
    String roomName,
  ) {
    final lang = L10n.of(context);
    final content = lang.shareInviteContent(inviteCode, roomName, displayName);
    return Wrap(
      direction: Axis.horizontal,
      alignment: WrapAlignment.center,
      spacing: 10,
      children: [
        _shareIntentsItem(
          context: context,
          iconData: PhosphorIconsThin.qrCode,
          onTap: () async {
            final userName = await ref.read(accountDisplayNameProvider.future);
            final userId = ref.read(myUserIdStrProvider);
            if (context.mounted) {
              showQrCode(
                context,
                'acter://acter.global/i/$inviteCode?roomDisplayName=$displayName&userId=$userId&userDisplayName=$userName',
                title: Text(lang.shareInviteWithCode(inviteCode)),
              );
            }
          },
        ),
        _shareIntentsItem(
          context: context,
          iconData: Atlas.envelope,
          onTap: () async => await mailTo(
            toAddress: '',
            subject: 'body=$content',
          ),
        ),
        _shareIntentsItem(
          context: context,
          iconData: Atlas.whatsapp,
          onTap: () async => await shareToWhatsApp(
            context,
            text: content,
          ),
        ),
        _shareIntentsItem(
          context: context,
          iconData: Icons.ios_share_sharp,
          onTap: () async {
            await Share.share(content);
          },
        ),
        _shareIntentsItem(
          context: context,
          iconData: Atlas.clipboard,
          onTap: () async {
            await Clipboard.setData(
              ClipboardData(text: content),
            );
            EasyLoading.showToast(lang.messageCopiedToClipboard);
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
          color: Theme.of(context).colorScheme.onSurface,
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
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      child: ActerPrimaryActionButton(
        onPressed: () => Navigator.pop(context),
        child: Text(L10n.of(context).done),
      ),
    );
  }
}
