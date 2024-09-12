import 'package:acter/common/providers/space_providers.dart';
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
