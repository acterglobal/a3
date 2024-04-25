import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/public_room_search/providers/public_space_info_provider.dart';
import 'package:acter/features/public_room_search/types.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::public_room_search::public_room_item');

class _JoinBtn extends ConsumerWidget {
  final PublicSearchResultItem item;
  final OnSelectedInnerFn onSelected;

  const _JoinBtn({
    required this.item,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(roomMembershipProvider(item.roomIdStr())).when(
          data: (data) =>
              data == null ? noMember(context) : alreadyMember(context),
          error: (error, st) {
            _log.severe('loading membership info failed', error, st);
            return Text(L10n.of(context).loadingFailed(error));
          },
          loading: () => Skeletonizer(
            child: OutlinedButton(
              onPressed: () => onSelected(
                item,
              ),
              child: Text(L10n.of(context).requestToJoin),
            ),
          ),
        );
  }

  Widget alreadyMember(BuildContext context) {
    return OutlinedButton(
      onPressed: () => onSelected(
        item,
      ),
      child: Text(L10n.of(context).member),
    );
  }

  Widget noMember(BuildContext context) {
    if (item.joinRuleStr() == 'Public') {
      return OutlinedButton(
        onPressed: () => onSelected(
          item,
        ),
        child: Text(L10n.of(context).join),
      );
    } else {
      return OutlinedButton(
        onPressed: () => onSelected(
          item,
        ),
        child: Text(L10n.of(context).requestToJoin),
      );
    }
  }
}

class PublicRoomItem extends ConsumerWidget {
  final PublicSearchResultItem item;
  final OnSelectedInnerFn onSelected;

  const PublicRoomItem({
    super.key,
    required this.item,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileInfo = ref.watch(searchItemProfileData(item));
    final topic = item.topic();

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: ListTile(
                onTap: () => onSelected(
                  item,
                ),
                leading: profileInfo.when(
                  data: (profile) => ActerAvatar(
                    mode: DisplayMode.Space,
                    avatarInfo: AvatarInfo(
                      uniqueId: item.roomIdStr(),
                      displayName: profile.displayName,
                      avatar: profile.getAvatarImage(),
                    ),
                  ),
                  error: (e, s) {
                    _log.severe('loading failed', e, s);
                    return fallbackAvatar();
                  },
                  loading: fallbackAvatar,
                ),
                title: Text(
                  item.name() ?? L10n.of(context).noDisplayName,
                  style: Theme.of(context).textTheme.labelLarge,
                  softWrap: false,
                ),
                subtitle: Text(
                  L10n.of(context).countsMembers(item.numJoinedMembers()),
                  style: Theme.of(context).textTheme.labelSmall,
                  softWrap: false,
                ),
                trailing: _JoinBtn(
                  item: item,
                  onSelected: onSelected,
                ),
              ),
            ),
          ),
          if (topic != null)
            Flexible(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  topic,
                  style: Theme.of(context).textTheme.labelMedium,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  ActerAvatar fallbackAvatar() {
    return ActerAvatar(
      mode: DisplayMode.Space,
      avatarInfo: AvatarInfo(
        uniqueId: item.roomIdStr(),
        displayName: item.name(),
      ),
    );
  }
}
