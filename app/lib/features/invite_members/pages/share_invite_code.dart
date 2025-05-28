import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/onboarding/types.dart';
import 'package:acter/features/share/widgets/external_share_options.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShareInviteCode extends ConsumerWidget {
  final String inviteCode;
  final String roomId;
  final CallNextPage? callNextPage;

  const ShareInviteCode({
    super.key,
    required this.inviteCode,
    required this.roomId,
    this.callNextPage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: callNextPage == null ? _buildAppBar(context) : null,
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
    final roomName =
        ref.watch(roomDisplayNameProvider(roomId)).valueOrNull ?? '';
    final String userName =
        ref.watch(accountDisplayNameProvider).valueOrNull ??
        ref.watch(myUserIdStrProvider);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMessageContent(context, ref, roomName, userName),
            const SizedBox(height: 30),
            _buildShareIntents(context, ref, roomName, userName),
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
    String roomName,
    String userName,
  ) {
    final lang = L10n.of(context);
    final content = lang.shareInviteContent(inviteCode, roomName, userName);
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
              child: SingleChildScrollView(child: Text(content)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareIntents(
    BuildContext context,
    WidgetRef ref,
    String roomName,
    String userName,
  ) {
    final lang = L10n.of(context);
    final userId = ref.read(myUserIdStrProvider);
    final qrContent =
        'acter:i/acter.global/$inviteCode?roomDisplayName=$roomName&userId=$userId&userDisplayName=$userName';
    final shareContent = lang.shareInviteContent(
      inviteCode,
      roomName,
      userName,
    );
    return ExternalShareOptions(
      qrContent: qrContent,
      shareContentBuilder: () async => shareContent,
    );
  }

  Widget _buildDoneButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ActerPrimaryActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Text(L10n.of(context).done),
      ),
    );
  }
}
