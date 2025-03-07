import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/categories/model/CategoryModelLocal.dart';
import 'package:acter/features/categories/utils/category_utils.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/spaces/providers/space_list_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CategoriesFor { spaces, chats, pins }

typedef CategoriesInfo = ({String spaceId, CategoriesFor categoriesFor});

final categoryManagerProvider = FutureProvider.family
    .autoDispose<Categories, CategoriesInfo>((ref, categoryInfo) async {
      final maybeSpace = await ref.watch(
        maybeSpaceProvider(categoryInfo.spaceId).future,
      );
      if (maybeSpace != null) {
        return maybeSpace.categories(categoryInfo.categoriesFor.name);
      }
      throw 'Space not found';
    });

final localCategoryListProvider = FutureProvider.family
    .autoDispose<List<CategoryModelLocal>, CategoriesInfo>((
      ref,
      categoryInfo,
    ) async {
      final categoriesManager = await ref.watch(
        categoryManagerProvider((
          spaceId: categoryInfo.spaceId,
          categoriesFor: categoryInfo.categoriesFor,
        )).future,
      );
      List<String> subEntriesList = [];

      if (categoryInfo.categoriesFor == CategoriesFor.spaces) {
        subEntriesList = await ref.watch(
          subSpacesListProvider(categoryInfo.spaceId).future,
        );
      } else if (categoryInfo.categoriesFor == CategoriesFor.chats) {
        subEntriesList = await ref.watch(
          subChatsListProvider(categoryInfo.spaceId).future,
        );
      }

      final categoryList = CategoryUtils().getCategorisedList(
        categoriesManager.categories().toList(),
        subEntriesList,
      );
      return categoryList;
    });
