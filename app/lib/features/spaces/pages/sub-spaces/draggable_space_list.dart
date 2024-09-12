import 'package:acter/common/widgets/spaces/space_card.dart';
import 'package:acter/features/spaces/pages/sub-spaces/category_header_view.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/material.dart';

class DraggableSpaceList extends StatefulWidget {
  final List<Category> categoryList;

  const DraggableSpaceList({
    super.key,
    required this.categoryList,
  });

  @override
  State<DraggableSpaceList> createState() => _DraggableSpaceListState();
}

class _DraggableSpaceListState extends State<DraggableSpaceList> {
  List<DragAndDropList>? dragAndDropList;

  @override
  void initState() {
    super.initState();
    setDragAndDropList();
  }

  void setDragAndDropList() {
    setState(() {
      dragAndDropList = List.generate(widget.categoryList.length, (index) {
        final spaceEntries = widget.categoryList[index]
            .entries()
            .map((s) => s.toDartString())
            .toList();
        return DragAndDropList(
          header: CategoryHeaderView(
            category: widget.categoryList[index],
          ),
          children: List<DragAndDropItem>.generate(
            spaceEntries.length,
            (index) => DragAndDropItem(
              child: SpaceCard(
                roomId: spaceEntries[index].toString(),
                margin: const EdgeInsets.symmetric(vertical: 6),
              ),
            ),
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildSubSpacesUIWithDrag();
  }

  Widget _buildSubSpacesUIWithDrag() {
    return dragAndDropList == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.all(12),
            child: DragAndDropLists(
              children: dragAndDropList!,
              onItemReorder: _onItemReorder,
              onListReorder: _onListReorder,
            ),
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
    });
  }
}
