import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final accountAvatarInfo = ref.watch(accountAvatarInfoProvider);
    final roomAvatarInfo = ref.watch(roomAvatarInfoProvider(roomId));
    final displayName = accountAvatarInfo.displayName ?? '';
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
              roomAvatarInfo.displayName ?? '',
            ),
            const SizedBox(height: 30),
            _buildShareIntents(
              context,
              displayName,
              roomAvatarInfo.displayName ?? '',
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
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              padding: const EdgeInsets.all(10),
              child: SingleChildScrollView(
                child: Text(
                  L10n.of(context)
                      .shareInviteContent(inviteCode, roomName, displayName),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareIntents(
    BuildContext context,
    String displayName,
    String roomName,
  ) {
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
              inviteCode,
              roomName,
              displayName,
            )}',
          ),
        ),
        _shareIntentsItem(
          context: context,
          iconData: Atlas.whatsapp,
          onTap: () => shareTextToWhatsApp(
            context,
            text: L10n.of(context).shareInviteContent(
              inviteCode,
              roomName,
              displayName,
            ),
          ),
        ),
        _shareIntentsItem(
          context: context,
          iconData: Icons.ios_share_sharp,
          onTap: () {
            Share.share(
              L10n.of(context).shareInviteContent(
                inviteCode,
                roomName,
                displayName,
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
                  inviteCode,
                  roomName,
                  displayName,
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
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: ActerPrimaryActionButton(
        onPressed: () => Navigator.pop(context),
        child: Text(L10n.of(context).done),
      ),
    );
  }
}
