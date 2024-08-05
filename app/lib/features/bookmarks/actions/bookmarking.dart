import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<bool> bookmark({
  required WidgetRef ref,
  required String key,
  required id,
}) async {
  final manager = await ref.read(bookmarksManagerProvider.future);
  return await manager.add(key, id);
}

Future<bool> unbookmark({
  required WidgetRef ref,
  required String key,
  required id,
}) async {
  final manager = await ref.read(bookmarksManagerProvider.future);
  return await manager.remove(key, id);
}
