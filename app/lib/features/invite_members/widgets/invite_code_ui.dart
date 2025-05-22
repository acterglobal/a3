import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/router/routes.dart';
import 'package:acter/common/widgets/dotted_border_widget.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter/features/super_invites/utils.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::invite::invite_code');

class InviteCodeUI extends ConsumerStatefulWidget {
  final String roomId;

  const InviteCodeUI({super.key, required this.roomId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _InviteCodeUIState();
}

class _InviteCodeUIState extends ConsumerState<InviteCodeUI> {
  SuperInviteToken? selectedToken;
  List<SuperInviteToken> allPossibleTokens = [];

  @override
  void initState() {
    super.initState();
    ref.listenManual(superInvitesForRoom(widget.roomId), (prev, asyncTokens) {
      final tokens = asyncTokens.valueOrNull ?? [];
      if (tokens.isEmpty) {
        // no tokens, keep empty
        setState(() {
          selectedToken = null;
          allPossibleTokens = [];
        });
        return;
      }

      SuperInviteToken newToken = tokens.firstWhere(
        (t) => t.rooms().isNotEmpty, // find the first that is only our room
        orElse: () => tokens.first, // or otherwise pick the first available
      );

      selectedToken.map((selected) {
        // we had a token selected, let’s try to find it again
        final tokenCode = selected.token();
        newToken = tokens.firstWhere(
          (t) => t.token() == tokenCode, // replace with teh updated one
          orElse: () => newToken,
        );
      });
      // auto select a token
      setState(() {
        selectedToken = newToken;
        allPossibleTokens = tokens;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    final inviteCode = selectedToken?.token();
    if (inviteCode == null) {
      return ActerPrimaryActionButton(
        onPressed: () => generateNewInviteCode(context, ref),
        child: Text(lang.generateInviteCode),
      );
    }

    final otherRoomsCount = (selectedToken?.rooms().length ?? 1) - 1;
    final hasMoreCodes = allPossibleTokens.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DottedBorderWidget(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(inviteCode, textAlign: TextAlign.center),
                    if (otherRoomsCount > 0)
                      Text(
                        lang.moreRooms(otherRoomsCount),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: inviteCode));
                  EasyLoading.showToast(lang.inviteCopiedToClipboard);
                },
                icon: const Icon(Icons.copy),
              ),
              if (hasMoreCodes)
                IconButton(
                  onPressed: () => selectInviteCodeDrawer(context, ref),
                  icon: const Icon(Icons.arrow_drop_down),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: ActerInlineTextButton(
            onPressed: () async {
              final token = await ref.read(
                superInviteTokenProvider(inviteCode).future,
              );
              if (!context.mounted) return;
              context.pushNamed(Routes.createSuperInvite.name, extra: token);
            },
            child: Text(lang.manage),
          ),
        ),
        const SizedBox(height: 10),
        ActerPrimaryActionButton(
          onPressed:
              () => context.pushNamed(
                Routes.shareInviteCode.name,
                queryParameters: {
                  'inviteCode': inviteCode,
                  'roomId': widget.roomId,
                },
              ),
          child: Text(lang.share),
        ),
      ],
    );
  }

  Future<void> selectInviteCodeDrawer(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showModalBottomSheet(
      showDragHandle: true,
      enableDrag: true,
      context: context,
      isDismissible: true,
      builder:
          (context) => Consumer(
            builder: (context, ref, child) {
              final lang = L10n.of(context);
              final inviteCodes =
                  ref.watch(superInvitesForRoom(widget.roomId)).valueOrNull ??
                  [];
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(child: Text(lang.select)),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context, null),
                          label: Text(lang.close),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: inviteCodes.length,
                      itemBuilder: (context, index) {
                        final invite = inviteCodes[index];
                        final otherRoomsCount =
                            (selectedToken?.rooms().length ?? 1) - 1;
                        return ListTile(
                          title: Text(invite.token()),
                          subtitle: Text(lang.moreRooms(otherRoomsCount)),
                          onTap: () {
                            setState(() => selectedToken = invite);
                            Navigator.pop(context, null);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> generateNewInviteCode(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final lang = L10n.of(context);
    try {
      EasyLoading.show(status: lang.generateInviteCode);
      final displayName = await ref.read(
        roomDisplayNameProvider(widget.roomId).future,
      );
      final inviteCode = generateInviteCodeName(displayName);

      await newSuperInviteForRooms(ref, [
        widget.roomId,
      ], inviteCode: inviteCode);
      ref.invalidate(superInvitesProvider);
      EasyLoading.dismiss();
    } catch (e, s) {
      _log.severe('Invite code activation failed', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.activateInviteCodeFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
