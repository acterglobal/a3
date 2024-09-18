import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/categories/model/CategoryModelLocal.dart';
import 'package:acter/features/categories/utils/category_utils.dart';
import 'package:acter/features/spaces/providers/space_list_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CategoriesFor { spaces, chats, pins }

typedef CategoriesInfo = ({String spaceId, CategoriesFor categoriesFor});

final categoryManagerProvider =
    FutureProvider.family<Categories, CategoriesInfo>(
        (ref, categoryInfo) async {
  final maybeSpace =
      await ref.watch(maybeSpaceProvider(categoryInfo.spaceId).future);
  if (maybeSpace != null) {
    return maybeSpace.categories(categoryInfo.categoriesFor.name);
  }
  throw 'Space not found';
});

final localCategoryListProvider = FutureProvider.family
    .autoDispose<List<CategoryModelLocal>, CategoriesInfo>(
        (ref, categoryInfo) async {
  final categoriesManager = await ref.read(
    categoryManagerProvider(
      (
        spaceId: categoryInfo.spaceId,
        categoriesFor: categoryInfo.categoriesFor
      ),
    ).future,
  );
  final subSpacesList =
      await ref.read(subSpacesListProvider(categoryInfo.spaceId).future);
  final categoryList = CategoryUtils().getCategorisedList(
    categoriesManager.categories().toList(),
    subSpacesList,
  );
  return categoryList;
});
