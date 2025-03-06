import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/common/widgets/dotted_border_widget.dart';
import 'package:acter/common/widgets/room/room_card.dart';
import 'package:acter/features/categories/actions/save_categories.dart';
import 'package:acter/features/categories/model/CategoryModelLocal.dart';
import 'package:acter/features/categories/providers/categories_providers.dart';
import 'package:acter/features/categories/utils/category_utils.dart';
import 'package:acter/features/categories/widgets/add_edit_category.dart';
import 'package:acter/features/categories/widgets/category_header_view.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class OrganizeCategoriesPage extends ConsumerStatefulWidget {
  final String spaceId;
  final CategoriesFor categoriesFor;

  const OrganizeCategoriesPage({
    super.key,
    required this.spaceId,
    required this.categoriesFor,
  });

  @override
  ConsumerState<OrganizeCategoriesPage> createState() =>
      _DraggableCategoriesListState();
}

class _DraggableCategoriesListState
    extends ConsumerState<OrganizeCategoriesPage> {
  List<DragAndDropList>? dragAndDropList;
  late List<CategoryModelLocal> categoryList;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => setDragAndDropList());
  }

  void setDragAndDropList() async {
    //GET LOCAL CATEGORY LIST
    categoryList = await ref.read(
      localCategoryListProvider((
        spaceId: widget.spaceId,
        categoriesFor: widget.categoriesFor,
      ),).future,
    );

    //SET DRAG AND DROP LIST DATA BASED ON THE LOCAL CATEGORY LIST
    setDragAndDropListData();
  }

  void setDragAndDropListData() {
    setState(() {
      dragAndDropList = List.generate(categoryList.length, (categoryIndex) {
        bool isLastItem = categoryIndex == categoryList.length - 1;
        return DragAndDropList(
          contentsWhenEmpty: DottedBorderWidget(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 35),
              child: Text('Drag here'),
            ),
          ),
          canDrag: CategoryUtils().isValidCategory(categoryList[categoryIndex]),
          header: dragDropListHeaderView(categoryIndex),
          children: getDragAndDropItemList(categoryIndex),
          lastTarget: SizedBox(height: isLastItem ? 100 : 20),
        );
      });
    });
  }

  //HEADER ITEM VIEW
  Widget dragDropListHeaderView(int categoryIndex) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: CategoryHeaderView(
        categoryModelLocal: categoryList[categoryIndex],
        isShowDragHandle: true,
        headerBackgroundColor: Theme.of(
          context,
        ).unselectedWidgetColor.withValues(alpha: 0.7),
        onClickEditCategory: () => callEditCategory(categoryIndex),
        onClickDeleteCategory: () => callDeleteCategory(categoryIndex),
      ),
    );
  }

  //EDIT CATEGORY (LOCALLY)
  void callEditCategory(int categoryIndex) {
    showAddEditCategoryBottomSheet(
      context: context,
      title: categoryList[categoryIndex].title,
      color: categoryList[categoryIndex].color,
      icon: categoryList[categoryIndex].icon,
      onSave: (title, color, icon) {
        CategoryModelLocal categoryModelLocal = CategoryModelLocal(
          title: title,
          color: color,
          icon: icon,
          entries: categoryList[categoryIndex].entries,
        );
        categoryList[categoryIndex] = categoryModelLocal;
        setDragAndDropListData();
      },
    );
  }

  //DELETE CATEGORY (LOCALLY)
  void callDeleteCategory(int categoryIndex) async {
    List<String> entriesOfDeleteCategory = categoryList[categoryIndex].entries;
    CategoryModelLocal unCategoriesItem = categoryList[categoryList.length - 1];
    unCategoriesItem.entries.insertAll(0, entriesOfDeleteCategory);
    categoryList.removeAt(categoryIndex);
    categoryList.removeAt(categoryList.length - 1);
    categoryList.add(unCategoriesItem);
    setDragAndDropListData();
  }

  //DRAG AND DROP ITEM LIST VIEW
  List<DragAndDropItem> getDragAndDropItemList(int categoryIndex) {
    return List<DragAndDropItem>.generate(
      categoryList[categoryIndex].entries.length,
      (entryItemIndex) => DragAndDropItem(
        child: RoomCard(
          roomId: categoryList[categoryIndex].entries[entryItemIndex],
          margin: const EdgeInsets.symmetric(vertical: 6),
          leading: Icon(PhosphorIcons.dotsSixVertical()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBarUI(),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildSubSpacesUIWithDrag()),
            _buildSaveCategoriesButton(),
          ],
        ),
      ),
    );
  }

  //APPBAR VIEW
  AppBar _buildAppBarUI() {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    final spaceName =
        ref.watch(roomDisplayNameProvider(widget.spaceId)).valueOrNull;
    return AppBar(
      leading: IconButton(
        onPressed: () async {
          await saveCategories(
            context,
            ref,
            widget.spaceId,
            widget.categoriesFor,
            categoryList,
          );
          if (mounted) Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lang.organize, style: textTheme.titleLarge),
          Text(
            '(${widget.categoriesFor.name} in $spaceName)',
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelLarge,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(PhosphorIcons.plus()),
          onPressed:
              () => showAddEditCategoryBottomSheet(
                context: context,
                bottomSheetTitle: lang.addCategory,
                onSave: callAddCategory,
              ),
        ),
      ],
    );
  }

  //ADD CATEGORY (LOCALLY)
  void callAddCategory(String title, Color color, ActerIcon icon) {
    categoryList.insert(
      0,
      CategoryModelLocal(title: title, color: color, icon: icon, entries: []),
    );
    setDragAndDropListData();
  }

  //DRAG AND DROP LIST VIEW
  Widget _buildSubSpacesUIWithDrag() {
    return dragAndDropList.map(
          (list) => DragAndDropLists(
            children: list,
            onListReorder: _onListReorder,
            onItemReorder: _onItemReorder,
          ),
        ) ??
        const Center(child: CircularProgressIndicator());
  }

  //ON HEADER ITEM REORDER
  Future<void> _onListReorder(int oldListIndex, int newListIndex) async {
    dragAndDropList.map((list) {
      final movedList = list.removeAt(oldListIndex);
      list.insert(newListIndex, movedList);

      final movedCategoryList = categoryList.removeAt(oldListIndex);
      categoryList.insert(newListIndex, movedCategoryList);

      setDragAndDropListData();
    });
  }

  //ON SUB ITEM REORDER
  Future<void> _onItemReorder(
    int oldItemIndex,
    int oldListIndex,
    int newItemIndex,
    int newListIndex,
  ) async {
    dragAndDropList.map((list) {
      final movedItem = list[oldListIndex].children.removeAt(oldItemIndex);
      list[newListIndex].children.insert(newItemIndex, movedItem);

      final movedEntryItem = categoryList[oldListIndex].entries.removeAt(
        oldItemIndex,
      );
      categoryList[newListIndex].entries.insert(newItemIndex, movedEntryItem);

      setDragAndDropListData();
    });
  }

  //SAVE ORGANIZED CATEGORIES
  Widget _buildSaveCategoriesButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ActerPrimaryActionButton(
        onPressed: () async {
          await saveCategories(
            context,
            ref,
            widget.spaceId,
            widget.categoriesFor,
            categoryList,
          );
          if (mounted) Navigator.pop(context);
        },
        child: Text(L10n.of(context).save),
      ),
    );
  }
}
