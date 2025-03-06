import 'package:acter/common/actions/redact_content.dart';
import 'package:acter/common/actions/report_content.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/like_button.dart';
import 'package:acter/common/widgets/visibility/shadow_effect_widget.dart';
import 'package:acter/features/comments/providers/comments_providers.dart';
import 'package:acter/features/comments/types.dart';
import 'package:acter/features/comments/widgets/comments_section_widget.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter/features/news/model/type/update_entry.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/features/notifications/types.dart';
import 'package:acter/features/notifications/widgets/object_notification_status.dart';
import 'package:acter/features/read_receipts/widgets/read_counter.dart';
import 'package:acter/features/share/action/share_space_object_action.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';

import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

final _log = Logger('a3::news::sidebar');

class NewsSideBar extends ConsumerWidget {
  final UpdateEntry updateEntry;

  const NewsSideBar({super.key, required this.updateEntry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final objectId = updateEntry.eventId().toString();
    final roomId = updateEntry.roomId().toString();
    final userId = ref.watch(myUserIdStrProvider);
    final isLikedByMe = ref.watch(likedByMeProvider(updateEntry));
    final likesCount = ref.watch(totalLikesForNewsProvider(updateEntry));
    final space = ref.watch(briefSpaceItemProvider(roomId));
    final style = Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 13);
    final commentCount =
        ref
            .watch(
              updateCommentsCountProvider(
                updateEntry.asCommentsManagerProvider(),
              ),
            )
            .valueOrNull ??
        0;
    final bodyLarge = Theme.of(context).textTheme.bodyLarge;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            const Spacer(),
            ReadCounterWidget(
              manager: updateEntry.readReceipts(),
              triggerAfterSecs: 3,
            ),
            const SizedBox(height: 5),
            LikeButton(
              isLiked: isLikedByMe.valueOrNull ?? false,
              likeCount: likesCount.valueOrNull ?? 0,
              style: bodyLarge?.copyWith(fontSize: 13),
              color: Theme.of(context).colorScheme.textColor,
              onTap: () async {
                final manager = await ref.read(
                  updateReactionsProvider(updateEntry).future,
                );
                final status = manager.likedByMe();
                _log.info('my like status: $status');
                if (!status) {
                  await manager.sendLike();
                } else {
                  await manager.redactLike(null, null);
                }
              },
            ),
            const SizedBox(height: 10),
            IconButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  useSafeArea: true,
                  builder:
                      (context) => CommentsSectionWidget(
                        managerProvider:
                            updateEntry.asCommentsManagerProvider(),
                        shrinkWrap: false,
                        centerTitle: true,
                        useCompactEmptyState: false,
                        autoSubscribeSection:
                            SubscriptionSubType
                                .comments, // we want to be using the comments only on boosts
                        actions: [
                          ObjectNotificationStatus(
                            objectId: objectId,
                            subType: SubscriptionSubType.comments,
                          ),
                        ],
                      ),
                );
              },
              icon: Column(
                children: [
                  ShadowEffectWidget(child: Icon(Atlas.comment_blank)),
                  const SizedBox(height: 4),
                  ShadowEffectWidget(
                    child: Text(commentCount.toString(), style: style),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              key: UpdateKeys.newsSidebarActionBottomSheet,
              onTap:
                  () => showModalBottomSheet(
                    showDragHandle: true,
                    useSafeArea: true,
                    context: context,
                    isScrollControlled: true,
                    isDismissible: true,
                    constraints: BoxConstraints(maxHeight: 300),
                    builder:
                        (context) => ActionBox(
                          news: updateEntry,
                          userId: userId,
                          roomId: roomId,
                        ),
                  ),
              child: _SideBarItem(
                icon: ShadowEffectWidget(
                  child: Icon(Atlas.dots_horizontal_thin),
                ),
                label: '',
                style: bodyLarge?.copyWith(fontSize: 13),
              ),
            ),
            const SizedBox(height: 10),
            isStory(updateEntry)
                ? buildUserAvatar(context, ref)
                : ActerAvatar(
                  options: AvatarOptions(
                    AvatarInfo(
                      uniqueId: roomId,
                      displayName: space.avatarInfo.displayName,
                      avatar: space.avatarInfo.avatar,
                      onAvatarTap: () => goToSpace(context, roomId),
                    ),
                    size: 42,
                  ),
                ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget buildUserAvatar(BuildContext context, WidgetRef ref) {
    final roomId = updateEntry.roomId().toString();
    final userId = updateEntry.sender().toString();
    final memberInfo = ref.watch(
      memberAvatarInfoProvider((roomId: roomId, userId: userId)),
    );
    return ActerAvatar(options: AvatarOptions.DM(memberInfo, size: 24));
  }
}

class _SideBarItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final TextStyle? style;

  const _SideBarItem({
    required this.icon,
    required this.label,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [icon, const SizedBox(height: 5), Text(label, style: style)],
    );
  }
}

class ActionBox extends ConsumerWidget {
  final String userId;
  final UpdateEntry news;
  final String roomId;

  const ActionBox({
    super.key,
    required this.news,
    required this.userId,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final senderId = news.sender().toString();
    final eventId = news.eventId().toString();
    final canRedact = ref.watch(canRedactProvider(news));
    final isAuthor = senderId == userId;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          lang.actions,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                icon: PhosphorIcon(PhosphorIcons.shareFat()),
                onPressed: () async {
                  final refDetails = await news.refDetails();
                  final internalLink = refDetails.generateInternalLink(true);
                  if (!context.mounted) return;
                  await openShareSpaceObjectDialog(
                    context: context,
                    refDetails: refDetails,
                    internalLink: internalLink,
                    showInternalActions: false,
                    shareContentBuilder: () async {
                      Navigator.pop(context);
                      return await refDetails.generateExternalLink();
                    },
                  );
                },
                label: Text(lang.share),
              ),
              if (canRedact.valueOrNull == true)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 5),
                  child: TextButton.icon(
                    key: UpdateKeys.newsSidebarActionRemoveBtn,
                    onPressed:
                        () => openRedactContentDialog(
                          context,
                          title: lang.removeThisPost,
                          eventId: eventId,
                          onSuccess: () async {
                            if (!await Navigator.maybePop(context)) {
                              if (context.mounted) {
                                // fallback to go to home
                                Navigator.pushReplacementNamed(
                                  context,
                                  Routes.main.name,
                                );
                              }
                            }
                          },
                          roomId: roomId,
                          isSpace: true,
                          removeBtnKey: UpdateKeys.removeButton,
                        ),
                    icon: const Icon(Atlas.trash_thin),
                    label: Text(lang.remove),
                  ),
                )
              else if (!isAuthor)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 5),
                  child: TextButton.icon(
                    key: UpdateKeys.newsSidebarActionReportBtn,
                    onPressed:
                        () => openReportContentDialog(
                          context,
                          title: lang.reportThisPost,
                          eventId: eventId,
                          description: lang.reportPostContent,
                          senderId: senderId,
                          roomId: roomId,
                          isSpace: true,
                        ),
                    icon: const Icon(Atlas.exclamation_chat_thin),
                    label: Text(lang.reportThis),
                  ),
                ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 5),
                child: ObjectNotificationStatus(
                  objectId: eventId,
                  includeText: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
