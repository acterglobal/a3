import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show EventSendState;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:quds_popup_menu/quds_popup_menu.dart';

class MessageMetadataBuilder extends ConsumerWidget {
  final String roomId;
  final types.Message message;

  const MessageMetadataBuilder({
    super.key,
    required this.roomId,
    required this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Map<String, int>? receipts = message.metadata?['receipts'];
    if (receipts != null && receipts.isNotEmpty) {
      return _UserReceiptsWidget(
        roomId: roomId,
        seenList: receipts.keys.toList(),
      );
    }
    EventSendState? sendState = message.metadata?['eventState'];
    final result = switch (sendState?.state()) {
      'NotSentYet' => const SizedBox(
        height: 8,
        width: 8,
        child: CircularProgressIndicator(),
      ),
      'SendingFailed' => Row(
        children: <Widget>[
          Icon(
            Atlas.warning_thin,
            color: Theme.of(context).colorScheme.error,
            size: 8,
          ),
          const SizedBox(width: 5),
          Text(L10n.of(context).chatSendingFailed),
          const SizedBox(width: 5),
          ActerInlineTextButton.icon(
            onPressed: () async {
              try {
                sendState?.abort();
              } catch (e) {
                EasyLoading.showError(L10n.of(context).error(e));
              }
            },
            icon: Icon(PhosphorIconsRegular.trash, size: 8),
            label: Text(L10n.of(context).cancel),
          ),
        ],
      ),
      'Sent' => const Icon(Atlas.check_circle_thin, size: 8),
      _ => null,
    };
    return result ?? const SizedBox.shrink();
  }
}

class _UserReceiptsWidget extends ConsumerWidget {
  static int limit = 5;

  final String roomId;
  final List<String> seenList;

  const _UserReceiptsWidget({required this.roomId, required this.seenList});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: QudsPopupButton(
        items: showDetails(),
        child: Wrap(
          spacing: -16,
          children:
              seenList.length > limit
                  ? [
                    for (final userId in seenList.sublist(0, limit))
                      Consumer(
                        builder: (context, ref, child) {
                          final memberProfile = ref.watch(
                            memberAvatarInfoProvider((
                              userId: userId,
                              roomId: roomId,
                            )),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ActerAvatar(
                              options: AvatarOptions.DM(memberProfile, size: 8),
                            ),
                          );
                        },
                      ),
                    CircleAvatar(
                      radius: 8,
                      child: Text(
                        '+${seenList.length - limit}',
                        textScaler: const TextScaler.linear(0.4),
                      ),
                    ),
                  ]
                  : [
                    for (final userId in seenList)
                      Consumer(
                        builder: (context, ref, child) {
                          final memberProfile = ref.watch(
                            memberAvatarInfoProvider((
                              userId: userId,
                              roomId: roomId,
                            )),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ActerAvatar(
                              options: AvatarOptions.DM(memberProfile, size: 8),
                            ),
                          );
                        },
                      ),
                  ],
        ),
      ),
    );
  }

  List<QudsPopupMenuBase> showDetails() {
    return [
      QudsPopupMenuWidget(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          final textTheme = Theme.of(context).textTheme;
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    L10n.of(context).seenBy,
                    style: textTheme.labelLarge,
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: seenList.length,
                  itemBuilder: (context, index) {
                    final userId = seenList[index];
                    return Consumer(
                      builder: (context, ref, child) {
                        final member = ref.watch(
                          memberAvatarInfoProvider((
                            userId: userId,
                            roomId: roomId,
                          )),
                        );
                        return ListTile(
                          leading: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ActerAvatar(
                              options: AvatarOptions.DM(member, size: 8),
                            ),
                          ),
                          title: Text(
                            member.displayName ?? userId,
                            style: textTheme.labelSmall,
                          ),
                          trailing: Text(
                            userId,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    ];
  }
}
