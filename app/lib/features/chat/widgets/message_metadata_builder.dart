import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Convo, EventSendState;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:quds_popup_menu/quds_popup_menu.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

final _log = Logger('a3::chat::message_metadata_builder');

class MessageMetadataBuilder extends ConsumerWidget {
  final Convo convo;
  final types.Message message;
  const MessageMetadataBuilder({
    super.key,
    required this.convo,
    required this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipts = message.metadata?['receipts'];
    EventSendState? sendState = message.metadata?['eventState'];
    if (receipts != null && receipts.isNotEmpty == true) {
      return _UserReceiptsWidget(
        roomId: convo.getRoomIdStr(),
        seenList: (receipts as Map<String, int>).keys.toList(),
      );
    } else {
      if (sendState != null) {
        switch (sendState.state()) {
          case 'NotSentYet':
            return const SizedBox(
              height: 8,
              width: 8,
              child: CircularProgressIndicator(),
            );
          case 'SendingFailed':
            return Row(
              children: <Widget>[
                GestureDetector(
                  onTap: () => _handleCancelRetrySend(context, ref),
                  child: Text(
                    L10n.of(context).cancelSend,
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: Theme.of(context).colorScheme.neutral5,
                          decoration: TextDecoration.underline,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _handleRetry(context, ref),
                  child: Text(
                    L10n.of(context).retry,
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: Theme.of(context).colorScheme.neutral5,
                          decoration: TextDecoration.underline,
                        ),
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  Atlas.warning_thin,
                  color: Theme.of(context).colorScheme.error,
                  size: 8,
                ),
              ],
            );
          case 'Sent':
            return const Icon(Atlas.check_circle_thin, size: 8);
        }
      }
      return const SizedBox.shrink();
    }
  }

  Future<void> _handleRetry(BuildContext context, WidgetRef ref) async {
    try {
      final stream = ref.read(timelineStreamProvider(convo));
      // attempts to retry sending local echo to server
      await stream.retrySend(message.id);
    } catch (e) {
      // ignore: use_build_context_synchronously
      EasyLoading.showError(L10n.of(context).failedToSend(e));
    }
  }

  Future<void> _handleCancelRetrySend(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final stream = ref.read(timelineStreamProvider(convo));
      // cancels the retry sending of local echos
      await stream.cancelSend(message.id);
    } catch (e) {
      // ignore: use_build_context_synchronously
      EasyLoading.showError(L10n.of(context).failedToSend(e));
    }
  }
}

class _UserReceiptsWidget extends ConsumerWidget {
  final String roomId;
  final List<String> seenList;
  const _UserReceiptsWidget({required this.roomId, required this.seenList});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limit = seenList.length > 5 ? 5 : seenList.length;
    final subList =
        limit == seenList.length ? seenList : seenList.sublist(0, limit);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: QudsPopupButton(
        items: showDetails(),
        child: Wrap(
          spacing: -16,
          children: limit != seenList.length
              ? [
                  for (var userId in subList)
                    Consumer(
                      builder: (context, ref, child) {
                        final memberProfile = ref.watch(
                          roomMemberProvider((userId: userId, roomId: roomId)),
                        );
                        return memberProfile.when(
                          data: (data) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ActerAvatar(
                                mode: DisplayMode.DM,
                                avatarInfo: AvatarInfo(
                                  uniqueId: userId,
                                  displayName:
                                      data.profile.displayName ?? userId,
                                  avatar: data.profile.getAvatarImage(),
                                ),
                                size: 8,
                              ),
                            );
                          },
                          error: (e, st) {
                            _log.severe('ERROR loading avatar', e, st);
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ActerAvatar(
                                mode: DisplayMode.DM,
                                avatarInfo: AvatarInfo(
                                  uniqueId: userId,
                                  displayName: userId,
                                ),
                                size: 8,
                              ),
                            );
                          },
                          loading: () => const SizedBox(
                            height: 8,
                            width: 8,
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    ),
                  CircleAvatar(
                    radius: 8,
                    child: Text(
                      '+${seenList.length - subList.length}',
                      textScaler: const TextScaler.linear(0.4),
                    ),
                  ),
                ]
              : List.generate(
                  seenList.length,
                  (idx) => Consumer(
                    builder: (context, ref, child) {
                      final memberProfile = ref.watch(
                        roomMemberProvider(
                          (userId: seenList[idx], roomId: roomId),
                        ),
                      );
                      final userId = seenList[idx];
                      return memberProfile.when(
                        data: (data) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ActerAvatar(
                              mode: DisplayMode.DM,
                              avatarInfo: AvatarInfo(
                                uniqueId: userId,
                                displayName: data.profile.displayName ?? userId,
                                avatar: data.profile.getAvatarImage(),
                              ),
                              size: 8,
                            ),
                          );
                        },
                        error: (e, st) {
                          _log.severe('ERROR loading avatar', e, st);
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ActerAvatar(
                              mode: DisplayMode.DM,
                              avatarInfo: AvatarInfo(
                                uniqueId: userId,
                                displayName: userId,
                              ),
                              size: 8,
                            ),
                          );
                        },
                        loading: () => const SizedBox(
                          height: 8,
                          width: 8,
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }

  List<QudsPopupMenuBase> showDetails() {
    return [
      QudsPopupMenuWidget(
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  L10n.of(context).seenBy,
                  style: Theme.of(context).textTheme.labelLarge,
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
                        roomMemberProvider(
                          (userId: userId, roomId: roomId),
                        ),
                      );
                      return ListTile(
                        leading: member.when(
                          data: (data) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ActerAvatar(
                                mode: DisplayMode.DM,
                                avatarInfo: AvatarInfo(
                                  uniqueId: seenList[index],
                                  displayName:
                                      data.profile.displayName ?? userId,
                                  avatar: data.profile.getAvatarImage(),
                                ),
                                size: 8,
                              ),
                            );
                          },
                          error: (e, st) {
                            _log.severe('ERROR loading avatar', e, st);
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ActerAvatar(
                                mode: DisplayMode.DM,
                                avatarInfo: AvatarInfo(
                                  uniqueId: userId,
                                  displayName: userId,
                                ),
                                size: 8,
                              ),
                            );
                          },
                          loading: () => const SizedBox(
                            height: 8,
                            width: 8,
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        title: Text(
                          member.hasValue
                              ? member.requireValue.profile.displayName!
                              : userId,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        trailing: Text(
                          userId,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall!
                              .copyWith(
                                color: Theme.of(context).colorScheme.neutral5,
                              ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ];
  }
}
