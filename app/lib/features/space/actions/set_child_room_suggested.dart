import 'package:acter/common/providers/space_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> setChildRoomSuggested(
  BuildContext context,
  WidgetRef ref, {
  required String parentId,
  required String roomId,
  required bool suggested,
}) async {
  //Fetch selected parent space data and add given roomId as child
  final space = await ref.read(spaceProvider(parentId).future);
  await space.addChildRoom(roomId, suggested);
}
