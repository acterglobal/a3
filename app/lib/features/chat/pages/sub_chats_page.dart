import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/skeletons/general_list_skeleton_widget.dart';
import 'package:acter/router/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/room/room_card.dart';
import 'package:acter/common/widgets/room/room_hierarchy_card.dart';
import 'package:acter/common/widgets/room/room_hierarchy_join_button.dart';
import 'package:acter/common/widgets/room/room_hierarchy_options_menu.dart';
import 'package:acter/features/categories/model/CategoryModelLocal.dart';
import 'package:acter/features/categories/providers/categories_providers.dart';
import 'package:acter/features/categories/widgets/category_header_view.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

final _log = Logger('a3::space::sub_chats');

class SubChatsPage extends ConsumerWidget {
  static const moreOptionKey = Key('sub-chats-more-actions');
  static const createSubChatKey = Key('sub-chats-more-create-subChat');
  static const linkSubChatKey = Key('sub-chats-more-link-subChat');

  final String spaceId;

  const SubChatsPage({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: _buildAppBarUI(context, ref),
      body: _buildSubChatsUI(context, ref),
    );
  }

  AppBar _buildAppBarUI(BuildContext context, WidgetRef ref) {
    final spaceName = ref.watch(roomDisplayNameProvider(spaceId)).valueOrNull;
    final membership = ref.watch(roomMembershipProvider(spaceId));
    bool canLinkSpace =
        membership.valueOrNull?.canString('CanLinkSpaces') == true;
    return AppBar(
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L10n.of(context).chats),
          Text(
            '($spaceName)',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(PhosphorIcons.arrowsClockwise()),
          onPressed: () {
            ref.invalidate(subChatsListProvider);
            ref.invalidate(localCategoryListProvider);
          },
        ),
        if (canLinkSpace) _buildMenuOptions(context),
      ],
    );
  }

  Widget _buildMenuOptions(BuildContext context) {
    final lang = L10n.of(context);
    return PopupMenuButton(
      icon: Icon(PhosphorIcons.dotsThreeVertical()),
      iconSize: 28,
      color: Theme.of(context).colorScheme.surface,
      itemBuilder:
          (BuildContext context) => <PopupMenuEntry>[
            PopupMenuItem(
              key: SubChatsPage.createSubChatKey,
              onTap:
                  () => context.pushNamed(
                    Routes.createChat.name,
                    queryParameters: {'spaceId': spaceId},
                    extra: 1,
                  ),
              child: Row(
                children: <Widget>[
                  Icon(PhosphorIcons.plus()),
                  const SizedBox(width: 6),
                  Text(lang.createChat),
                ],
              ),
            ),
            PopupMenuItem(
              key: SubChatsPage.linkSubChatKey,
              onTap:
                  () => context.pushNamed(
                    Routes.linkChat.name,
                    pathParameters: {'spaceId': spaceId},
                  ),
              child: Row(
                children: <Widget>[
                  Icon(PhosphorIcons.link()),
                  const SizedBox(width: 6),
                  Text(lang.linkExistingChat),
                ],
              ),
            ),
            PopupMenuItem(
              onTap:
                  () => context.pushNamed(
                    Routes.organizeCategories.name,
                    pathParameters: {
                      'spaceId': spaceId,
                      'categoriesFor': CategoriesFor.chats.name,
                    },
                  ),
              child: Row(
                children: [
                  Icon(PhosphorIcons.dotsSixVertical()),
                  const SizedBox(width: 6),
                  Text(lang.organize),
                ],
              ),
            ),
          ],
    );
  }

  Widget _buildSubChatsUI(BuildContext context, WidgetRef ref) {
    final localCategoryList = ref.watch(
      localCategoryListProvider((
        spaceId: spaceId,
        categoriesFor: CategoriesFor.chats,
      )),
    );

    return localCategoryList.when(
      data:
          (categoryList) => ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: categoryList.length,
            itemBuilder:
                (BuildContext context, int index) =>
                    _buildCategoriesList(context, ref, categoryList[index]),
          ),
      error: (e, s) {
        _log.severe('Failed to load the sub-spaces', e, s);
        return Center(child: Text(L10n.of(context).loadingFailed(e)));
      },
      loading: () => const GeneralListSkeletonWidget(),
    );
  }

  Widget _buildCategoriesList(
    BuildContext context,
    WidgetRef ref,
    CategoryModelLocal categoryModelLocal,
  ) {
    final knownChats =
        ref
            .watch(spaceRelationsOverviewProvider(spaceId))
            .valueOrNull
            ?.knownChats ??
        [];
    final remoteSubchats =
        ref.watch(remoteChatRelationsProvider(spaceId)).valueOrNull ?? [];
    final List<(SpaceHierarchyRoomInfo?, String)> entries = [];

    for (final subId in categoryModelLocal.entries) {
      if (knownChats.contains(subId)) {
        // user already knows this one
        entries.add((null, subId));
      } else {
        for (final r in remoteSubchats) {
          if (r.roomIdStr() == subId) {
            if (r.joinRuleStr().toLowerCase() != 'private') {
              // we ignore private cases
              entries.add((r, subId));
            }

            break; // room was found but ignored
          }
        }
      }
    }
    if (entries.isEmpty) {
      // nothing to show, hide category
      return const SizedBox.shrink();
    }
    final suggestedChats =
        ref.watch(suggestedChatsProvider(spaceId)).valueOrNull;
    final suggestedChatIds = [];
    if (suggestedChats != null &&
        (suggestedChats.$1.isNotEmpty || suggestedChats.$2.isNotEmpty)) {
      suggestedChatIds.addAll(suggestedChats.$1);
      suggestedChatIds.addAll(suggestedChats.$2);
    }

    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.only(right: 16),
        initiallyExpanded: true,
        showTrailingIcon: !categoryModelLocal.isUncategorized,
        enabled: !categoryModelLocal.isUncategorized,
        minTileHeight: categoryModelLocal.isUncategorized ? 0 : null,
        shape: const Border(),
        collapsedBackgroundColor: Colors.transparent,
        title:
            categoryModelLocal.isUncategorized
                ? const SizedBox.shrink()
                : CategoryHeaderView(categoryModelLocal: categoryModelLocal),
        children: List<Widget>.generate(entries.length, (index) {
          final roomEntry = entries[index];
          final roomInfo = roomEntry.$1;
          final roomId = roomEntry.$2;
          if (roomInfo != null) {
            // we don’t have this room yet, need to show via room hierarchy
            final parentId = spaceId;
            return RoomHierarchyCard(
              key: Key('subchat-list-item-$roomId'),
              roomInfo: roomInfo,
              parentId: parentId,
              indicateIfSuggested: true,
              trailing: Wrap(
                children: [
                  RoomHierarchyJoinButton(
                    joinRule: roomInfo.joinRuleStr().toLowerCase(),
                    roomId: roomId,
                    roomName: roomInfo.name() ?? roomId,
                    viaServerName: roomInfo.viaServerNames().toDart(),
                    forward: (spaceId) {
                      goToChat(context, spaceId);
                      ref.invalidate(spaceRelationsProvider(parentId));
                      ref.invalidate(spaceRemoteRelationsProvider(parentId));
                    },
                  ),
                  RoomHierarchyOptionsMenu(
                    isSuggested: roomInfo.suggested(),
                    childId: roomId,
                    parentId: parentId,
                  ),
                ],
              ),
            );
          }

          final isSuggested = suggestedChatIds.contains(roomId);
          return RoomCard(
            roomId: roomId,
            showParents: false,
            showVisibilityMark: true,
            showSuggestedMark: isSuggested,
            trailing: RoomHierarchyOptionsMenu(
              childId: roomId,
              parentId: spaceId,
              isSuggested: isSuggested,
            ),
            onTap: () => goToChat(context, roomId),
            margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          );
        }),
      ),
    );
  }
}
