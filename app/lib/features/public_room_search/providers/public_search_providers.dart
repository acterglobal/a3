import 'package:acter/features/public_room_search/providers/notifiers/public_spaces_notifier.dart';
import 'package:acter/features/public_room_search/types.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';

final serverTypeAheadController =
    Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  final typeNotifier = ref.read(serverTypeAheadProvider.notifier);
  controller.addListener(() {
    typeNotifier.state = controller.text;
  });
  ref.onDispose(() {
    controller.dispose();
    typeNotifier.state = null;
  });
  return controller;
});

final searchController = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() {
    controller.dispose();
    ref.read(searchValueProvider.notifier).state = null;
  });
  return controller;
});

final publicSearchProvider = StateNotifierProvider.autoDispose<
    PublicSearchNotifier, PagedState<Next?, PublicSearchResultItem>>((ref) {
  return PublicSearchNotifier(ref);
});

final searchValueProvider = StateProvider<String?>((ref) => null);
final serverTypeAheadProvider = StateProvider<String?>((ref) => null);
final selectedServerProvider = StateProvider<String?>((ref) => null);
