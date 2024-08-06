import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:acter/features/bookmarks/types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<bool> bookmark({
  required WidgetRef ref,
  required Bookmarker bookmarker,
}) async {
  final manager = await ref.read(bookmarksManagerProvider.future);
  return await manager.add(bookmarker.type.name, bookmarker.id);
}

Future<bool> unbookmark({
  required WidgetRef ref,
  required Bookmarker bookmarker,
}) async {
  final manager = await ref.read(bookmarksManagerProvider.future);
  return await manager.remove(bookmarker.type.name, bookmarker.id);
}
