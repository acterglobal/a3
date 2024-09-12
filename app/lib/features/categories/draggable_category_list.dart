import 'package:acter/common/widgets/spaces/space_card.dart';
import 'package:acter/features/categories/actions/save_categories.dart';
import 'package:acter/features/categories/providers/categories_providers.dart';
import 'package:acter/features/categories/widgets/category_header_view.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class DraggableCategoryList extends ConsumerStatefulWidget {
  final String spaceId;
  final CategoriesFor categoriesFor;

  const DraggableCategoryList({
    super.key,
    required this.spaceId,
    required this.categoriesFor,
  });

  @override
  ConsumerState<DraggableCategoryList> createState() =>
      _DraggableCategoriesListState();
}

class _DraggableCategoriesListState
    extends ConsumerState<DraggableCategoryList> {
  List<DragAndDropList>? dragAndDropList;
  late List<Category> categoryList;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => setDragAndDropList());
  }

  void setDragAndDropList() async {
    final categoriesManager = await ref.read(
      categoryManagerProvider(
        (spaceId: widget.spaceId, categoriesFor: widget.categoriesFor),
      ).future,
    );
    categoryList = categoriesManager.categories().toList();
    setDragAndDropListData();
  }

  void setDragAndDropListData() {
    dragAndDropList = List.generate(categoryList.length, (index) {
      final spaceEntries =
          categoryList[index].entries().map((s) => s.toDartString()).toList();
      return DragAndDropList(
        header: Padding(
          padding: const EdgeInsets.all(14),
          child: CategoryHeaderView(
            category: categoryList[index],
            isShowDragHandle: true,
          ),
        ),
        children: List<DragAndDropItem>.generate(
          spaceEntries.length,
          (index) => DragAndDropItem(
            child: SpaceCard(
              roomId: spaceEntries[index].toString(),
              margin: const EdgeInsets.symmetric(vertical: 6),
              trailing: Icon(PhosphorIcons.dotsSixVertical()),
            ),
          ),
        ),
      );
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAppBarUI(),
            const Divider(endIndent: 0, indent: 0),
            Expanded(
              child: Stack(
                children: [
                  _buildSubSpacesUIWithDrag(),
                  Positioned.fill(child: _buildActionButtons()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarUI() {
    return Row(
      children: [
        Text(
          L10n.of(context).organized,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Spacer(),
        IconButton(
          icon: Icon(PhosphorIcons.x()),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final buttonStyle = OutlinedButton.styleFrom(
      backgroundColor: Theme.of(context).primaryColor,
    );
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 30),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.8),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: OutlinedButton(
                style: buttonStyle,
                onPressed: () => Navigator.pop(context),
                child: Text(L10n.of(context).createCategory),
              ),
            ),
            const SizedBox(width: 30),
            Expanded(
              child: OutlinedButton(
                style: buttonStyle,
                onPressed: () => saveCategories(
                  context,
                  ref,
                  widget.spaceId,
                  widget.categoriesFor,
                  categoryList,
                ),
                child: Text(L10n.of(context).save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubSpacesUIWithDrag() {
    return dragAndDropList == null
        ? const SizedBox.shrink()
        : DragAndDropLists(
            children: dragAndDropList!,
            onItemReorder: _onItemReorder,
            onListReorder: _onListReorder,
          );
  }

  Future<void> _onItemReorder(
    int oldItemIndex,
    int oldListIndex,
    int newItemIndex,
    int newListIndex,
  ) async {
    if (dragAndDropList == null) return;
    setState(() {
      var movedItem =
          dragAndDropList![oldListIndex].children.removeAt(oldItemIndex);
      dragAndDropList![newListIndex].children.insert(newItemIndex, movedItem);

      ///MOVE ENTRY ITEM ON SAME CATEGORY
      if (oldListIndex == newListIndex) {
        //GET OLDER CATEGORY ITEM
        final oldCategoryItem = categoryList[oldListIndex];

        //GET OLDER CATEGORY ITEM DATA IN LOCAL
        final spaceEntries =
            oldCategoryItem.entries().map((s) => s.toDartString()).toList();

        //REMOVE SPACE ENTRY FROM SPECIFIED POSITION
        var movedEntryItem = spaceEntries.removeAt(oldItemIndex);

        //ADD SPACE ENTRY FROM SPECIFIED POSITION
        spaceEntries.insert(newItemIndex, movedEntryItem);

        //UPDATE CATEGORY ITEM
        final categoryItemBuilder = oldCategoryItem.updateBuilder();
        categoryItemBuilder.clearEntries();
        for (int j = 0; j < spaceEntries.length; j++) {
          categoryItemBuilder.addEntry(spaceEntries[j]);
        }

        //REMOVE OLDER CATEGORY ITEM FROM SPECIFIED POSITION
        categoryList.removeAt(oldListIndex);

        //SAVE NEW CATEGORY ITEM AT SPECIFIED POSITION
        final newCategoryItem = categoryItemBuilder.build();
        categoryList.insert(newListIndex, newCategoryItem);
      } else {
        ///MOVE ENTRY ITEM NOT ON SAME CATEGORY
        final oldCategoryItem = categoryList[oldListIndex];

        //GET OLDER CATEGORY ITEM DATA IN LOCAL
        final oldCategoryItemSpaceEntries =
            oldCategoryItem.entries().map((s) => s.toDartString()).toList();

        //REMOVE SPACE ENTRY FROM SPECIFIED POSITION
        var movedEntryItem = oldCategoryItemSpaceEntries.removeAt(oldItemIndex);

        //UPDATE OLD CATEGORY ITEM
        final oldCategoryItemBuilder = oldCategoryItem.updateBuilder();
        oldCategoryItemBuilder.clearEntries();
        for (int j = 0; j < oldCategoryItemSpaceEntries.length; j++) {
          oldCategoryItemBuilder.addEntry(oldCategoryItemSpaceEntries[j]);
        }
        categoryList[oldListIndex] = oldCategoryItemBuilder.build();

        final newCategoryItem = categoryList[newListIndex];

        //GET NEW CATEGORY ITEM DATA IN LOCAL
        final newCategoryItemSpaceEntries =
            newCategoryItem.entries().map((s) => s.toDartString()).toList();

        //REMOVE SPACE ENTRY FROM SPECIFIED POSITION
        newCategoryItemSpaceEntries.insert(newItemIndex, movedEntryItem);

        //UPDATE OLD CATEGORY ITEM
        final newCategoryItemBuilder = newCategoryItem.updateBuilder();
        newCategoryItemBuilder.clearEntries();
        for (int j = 0; j < newCategoryItemSpaceEntries.length; j++) {
          newCategoryItemBuilder.addEntry(newCategoryItemSpaceEntries[j]);
        }
        categoryList[newListIndex] = newCategoryItemBuilder.build();
      }
    });
  }

  Future<void> _onListReorder(
    int oldListIndex,
    int newListIndex,
  ) async {
    if (dragAndDropList == null) return;
    setState(() {
      var movedList = dragAndDropList!.removeAt(oldListIndex);
      dragAndDropList!.insert(newListIndex, movedList);

      var movedCategoryList = categoryList.removeAt(oldListIndex);
      categoryList.insert(newListIndex, movedCategoryList);
    });
  }
}
