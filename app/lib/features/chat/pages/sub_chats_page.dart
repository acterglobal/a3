import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/skeletons/general_list_skeleton_widget.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/room/room_card.dart';
import 'package:acter/common/widgets/room/room_hierarchy_options_menu.dart';
import 'package:acter/features/categories/model/CategoryModelLocal.dart';
import 'package:acter/features/categories/providers/categories_providers.dart';
import 'package:acter/features/categories/utils/category_utils.dart';
import 'package:acter/features/categories/widgets/category_header_view.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
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
    return PopupMenuButton(
      icon: Icon(PhosphorIcons.dotsThreeVertical()),
      iconSize: 28,
      color: Theme.of(context).colorScheme.surface,
      itemBuilder: (BuildContext context) => <PopupMenuEntry>[
        PopupMenuItem(
          key: SubChatsPage.createSubChatKey,
          onTap: () => context.pushNamed(
            Routes.createChat.name,
            queryParameters: {'parentSpaceId': spaceId},
          ),
          child: Row(
            children: <Widget>[
              Icon(PhosphorIcons.plus()),
              const SizedBox(width: 6),
              Text(L10n.of(context).createChat),
            ],
          ),
        ),
        PopupMenuItem(
          key: SubChatsPage.linkSubChatKey,
          onTap: () => context.pushNamed(
            Routes.linkChat.name,
            pathParameters: {'spaceId': spaceId},
          ),
          child: Row(
            children: <Widget>[
              Icon(PhosphorIcons.link()),
              const SizedBox(width: 6),
              Text(L10n.of(context).linkExistingChat),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () => context.pushNamed(
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
              Text(L10n.of(context).organize),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubChatsUI(BuildContext context, WidgetRef ref) {
    final localCategoryList = ref.watch(
      localCategoryListProvider(
        (
          spaceId: spaceId,
          categoriesFor: CategoriesFor.chats,
        ),
      ),
    );

    return localCategoryList.when(
      data: (localCategoryListData) {
        final categoryList = CategoryUtils()
            .getCategorisedListWithoutEmptyEntries(localCategoryListData);
        return ListView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: categoryList.length,
          itemBuilder: (BuildContext context, int index) {
            return _buildCategoriesList(context, ref, categoryList[index]);
          },
        );
      },
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
    final entries = categoryModelLocal.entries;

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
        shape: const Border(),
        collapsedBackgroundColor: Colors.transparent,
        title: CategoryHeaderView(categoryModelLocal: categoryModelLocal),
        children: List<Widget>.generate(entries.length, (index) {
          final roomId = entries[index];
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
            margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          );
        }),
      ),
    );
  }
}
